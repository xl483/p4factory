/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

header_type egress_filter_metadata_t {
    fields {
        ifindex : IFINDEX_BIT_WIDTH;           /* src port filter */
        bd : BD_BIT_WIDTH;                     /* bd for src port filter */
        inner_bd : BD_BIT_WIDTH;               /* split horizon filter */
    }
}
metadata egress_filter_metadata_t egress_filter_metadata;

action set_egress_ifindex(egress_ifindex) {
    bit_xor(egress_filter_metadata.ifindex, ingress_metadata.ifindex,
            egress_ifindex);
    bit_xor(egress_filter_metadata.bd, ingress_metadata.outer_bd,
            egress_metadata.bd);
    bit_xor(egress_filter_metadata.inner_bd, ingress_metadata.bd,
            ingress_metadata.egress_bd);
}

table egress_lag {
    reads {
        standard_metadata.egress_port : exact;
    }
    actions {
        set_egress_ifindex;
    }
}

action set_egress_filter_drop() {
    drop();
}

table egress_filter {
    actions {
        set_egress_filter_drop;
    }
}

control process_egress_filter {
    apply(egress_lag);
    if (((tunnel_metadata.egress_tunnel_type != EGRESS_TUNNEL_TYPE_NONE) and
         (egress_metadata.inner_replica == TRUE) and
         (egress_filter_metadata.inner_bd == 0)) or
        ((egress_filter_metadata.ifindex == 0) and
         (egress_filter_metadata.bd == 0))) {
        apply(egress_filter);
    }
}
