# UMBRA model artifacts

`umbra_dqn_weights.json` is the preserved legacy export (22 outputs, no versioned
ABI metadata). It is incompatible with the 23-action runtime contract and must
not be renamed, padded, or relabeled to enable it.

The runtime and `tools/export_umbra_weights.py` use
`umbra_dqn_2_0_actions_23.json` for the compatible model. This artifact is not
currently available. The existing non-DQN decision fallback remains active;
reward, heuristics and network architecture are unchanged.

Export a genuinely trained model with shapes `24 -> 128 -> 64 -> 23` using the
exporter's exact action/feature order. The loader continues rejecting invalid
version, schema, ordering or shape with a specific error. No fabricated weights
are shipped by the reconciliation.
