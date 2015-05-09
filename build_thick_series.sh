#! /bin/bash

# script generate series of pDOS jobs 
#   for thickness testing 
#   for Quantum ESPRESSO input files
echo "Building thickness testing files"
################################################
# The following sample files should 
#   be prepared in the `workdir`
prfx=au111
scf_samplefile=$prfx.scf.in
pdos_fname=$prfx.pdos.in
pbs_fname=$prfx.pbs
################################################
workdir=/home/jinxi/pwjobs/au_surface_proj
# nscf file generated from scf sample file
nscf_fname=$prfx.nscf.in
maxthick=25
incr=2
minthick=5
layersep=2.4017771
itrdirprefx=${prfx}_lyr
# submit_pbs = auto / manual
submit_pbs='auto'

doskpt_x=45
doskpt_y=45

cd $workdir

for (( i=$maxthick; i>=$minthick; i-=$incr ))
do
  echo "building thickness $i"
  itrdir=$itrdirprefx$i
  mkdir $itrdir
  ##########################
  # dealing with scf input
  ##########################
  cp $scf_samplefile $itrdir
  modfile=$itrdir/$scf_samplefile
  # modify total atomic number
  sed -i -r "s/(nat=).*/\1$i,/" $modfile
  # find the line number of begining atomic coordinate 
  nln_coord=`sed -n '/ATOMIC_POSITIONS/=' $modfile`
  nln_del_start=`expr $nln_coord + $i`
  pttn_start=`sed -n "$nln_del_start p" $modfile`
  nln_del_limit=`sed -n '/K_POINTS/=' $modfile`
  echo Del start at $nln_del_start, limit at $nln_del_limit
  # check if thickness of sample file is enough
  if [ $nln_del_start -ge $nln_del_limit ]; then
    echo no enough layers in sample file
    exit 0
  fi
  # delete coordinate lines exclude patterns
  sed -i "/$pttn_start/,/K_POINTS/{//!d}" $modfile
  # calc the cell period of z-axis and replace 
  #   to cell parameter
  zcell=$(echo "20.0 + $layersep*($i-1)"|bc)
  echo z-axis of cell,  $zcell
  nln_cellpar=`sed -n '/CELL_PARAMETERS/=' $modfile`
  nln_zcell=`expr $nln_cellpar + 3`
  ln_zcoord_old=`sed -n "$nln_zcell p" $modfile`
  ln_zcoord_new=`sed -e "s/[^ ]*[^ ]/$zcell/3" <<< $ln_zcoord_old`
  echo $ln_zcoord_new
  sed -i "${nln_zcell}s/[^ ].*/$ln_zcoord_new/" $modfile
  ##########################
  # dealing with nscf input
  ##########################
  cp $itrdir/$scf_samplefile $itrdir/$nscf_fname
  nscff=$itrdir/$nscf_fname
  # change eigen mode, to 'nscf'
  sed -i -r "s/(calculation =).*/\1'nscf',/" $nscff
  nln_kptstag=`sed -n '/K_POINTS/=' $nscff`
  nln_kpts=`expr $nln_kptstag + 1`
  ln_kpts_old=`sed -n "$nln_kpts p" $nscff`
  ln_kpts_new=`sed -e "s/[^ ]*[^ ][ ]*[^ ]*[^ ]/$doskpt_x $doskpt_y/1" <<< $ln_kpts_old`
  echo $ln_kpts_new
  sed -i "${nln_kpts}s/[^ ].*/$ln_kpts_new/" $nscff
  ##########################
  # dealing with pdos input
  ##########################
  cp $pdos_fname $itrdir/$pdos_fname
  ##########################
  # dealing with pbs input
  ##########################
  cp $pbs_fname $itrdir/$pbs_fname
  pbsf=$itrdir/$pbs_fname
  # change queue name
  sed -i -r "s/(#PBS -N ).*/\1 ${itrdirprefx}$i/" $pbsf
done




