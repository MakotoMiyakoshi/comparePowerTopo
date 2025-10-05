# comparePowerTopo

Compares power topographies between two EEGLAB datasets across specified frequency bands.

## Overview

comparePowerTopo loads two EEGLAB datasets and computes power topographies in user-defined frequency bands using a band-pass filter. The function provides a GUI-based workflow to facilitate user input and data selection.

## Features

GUI-based input for file paths and frequency band specification

Band-pass filtering using FIR Hamming window filter (−53 dB/octave attenuation)

Supports 10–20 system channel labels (e.g., Fz, Cz, Pz)

Topographic visualization of power differences across scalp

## Workflow

The function launches three GUI prompts:

Dataset 1 – Select first EEGLAB dataset (.set)

Dataset 2 – Select second EEGLAB dataset (.set)

Frequency Band – Enter lower and upper cutoff frequencies (e.g., [8 12] for alpha)

## Requirements

EEGLAB structure with full channel info or standard 10–20 labels

MATLAB with EEGLAB installed

## Filter Details

Type: FIR filter using Hamming window

Transition Bandwidth: Fixed at 1 Hz

Design: Band-pass with user-specified cutoff frequencies
