---
title:          "NeutronOrch: Rethinking Sample-based GNN Training under CPU-GPU Heterogeneous Environments"
date:           2024-02-01 00:01:00 +0800
selected:       false
pub:            "Very Large Data Bases (VLDB)"
# pub_pre:        "Submitted to "
# pub_post:       'Under review.'
# pub_last:       ' <span class="badge badge-pill badge-publication badge-success">Spotlight</span>'
pub_date:       "2024"

abstract: >-
  In this paper, we propose NeutronOrch, a system for sample-based GNN training that incorporates a layer-based task orchestrating method and ensures balanced utilization of the CPU and GPU. NeutronOrch decouples the training process by layer and pushes down the training task of the bottom layer to the CPU. This significantly reduces the computational load and memory footprint of GPU training. 
cover:          /assets/images/covers/vldb-neutronorch.png
authors:
  - Xin Ai
  - Qiange Wang
  - Chunyu Cao
  - Yanfeng Zhang
  - Chaoyi Chen
  - "<b style='font-weight:900;color:#000;'>Hao Yuan</b>"
  - Yu Gu
  - Ge Yu
links:
  Code: https://github.com/iDC-NEU/NeutronOrch
  Slides: https://idc-neu.github.io/slides/NeutronOrch_VLDB24.pdf
---
