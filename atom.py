#! /usr/bin/python3

import numpy as np
import sys

class Atom:

    def __init__(self, atomid, elem):
        '''
        self.atomid : atom ID in output, string
        self.elem : element of atom, string
        '''
        self.atomid = atomid
        self.elem = elem

    def get_pdos(self, oupfpre, orbitals, spin=True, poupfname=False):
        '''
        Read the pdos files of the atom, created by ``projwfc.x``.
        the output structure is explained in ``Doc/INPUT_PROJWFC.html``.

        pdos file structure:
        ====================
        <beginning of file>
        # E (eV)  ldosup(E)  ldosdw(E) pdosup(E)  pdosdw(E)  ...
         -6.759  0.944E-07  0.942E-07  0.944E-07  0.942E-07  ...
         ...
         ...
        <end of file>

        pdos : projected on each atomic orbitals, e.g., p_x, p_y, p_z
        ldos : sum of pdos

        INPUT:
        ======
        oupfpre : prefix of pdos files, indicated by QE input ``filpdos`` of projwfc.x 
        readpdos : if True, read pdos and ldos
                   if False, read only ldos
        orbitals : dictionary of angular projection orbitals, 
                   orbitals = {
                               's': ['tot'],
                               'p': ['tot', 'z', 'x', 'y'],
                               'd': ['tot', 'z2', 'zx', 'zy', 'x2-y2', 'xy'], 
                              }

        NEW Attributes:
        ===============
        self.pdos = { 'enary': np.array[energy array], 
                      's': { 'tot': np.array[tot array], }
                      'p': { 'tot': np.array[tot array],
                             'z': np.array[z array],
                             ...
                           }
                      ...
                    }
        '''
        # dictionary building correspondence of orbital ID
        orbital_dict = { 's':'1', 'p':'2', 'd':'3', 'f':'4' }
        anglr_col = { 'tot':1, 
                      'z':2,
                      'x':3,
                      'y':4,
                      'z2':   2,
                      'zx':   3,
                      'zy':   4,
                      'x2-y2':5,
                      'xy':   6,
                    }
        self.pdos = {}
        for orbital, angularlist in orbitals.items():
            pdosfname = oupfpre + \
                        '.pdos_atm#' + str(self.atomid) + \
                        '(' + self.elem + ')_wfc#' + \
                        orbital_dict[orbital] + '(' + orbital + ')'
            if poupfname:
                print('Reading', pdosfname, '...')
            cols = np.loadtxt(pdosfname, unpack=True)
            if 'enary' not in self.pdos:
                self.pdos['enary'] = cols[0]
            for angular in angularlist:
                self.pdos[orbital] = {}
                self.pdos[orbital][angular] = cols[anglr_col[angular]]

