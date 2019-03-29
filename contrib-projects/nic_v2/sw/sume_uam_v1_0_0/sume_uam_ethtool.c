/*
 * Copyright (c) 2016 Vincenzo Maffione
 * Copyright (c) 2016 Marcin Wójcik
 * All rights reserved.
 *
 * This software was developed by
 * Stanford University and the University of Cambridge Computer Laboratory
 * under National Science Foundation under Grant No. CNS-0855268,
 * the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
 * by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
 * as part of the DARPA MRC research programme and under the SSICLOPS (grant
 * agreement No. 644866) project as part of the European Union’s Horizon 2020
 * research and innovation programme 2014-2018.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#include "sume_uam.h"

static void sume_uam_get_drvinfo(struct net_device *netdev, struct ethtool_drvinfo *drvinfo) {
	strlcpy(drvinfo->driver, "SUME_UAM_DRIVER", 16);
	strlcpy(drvinfo->version, "0.1", 4);
	strlcpy(drvinfo->fw_version, "0.0-1", 6);
	strlcpy(drvinfo->bus_info, "SOME_BUS_INFO", 14);
	drvinfo->regdump_len = 0;
	drvinfo->eedump_len = 0;
}

static const struct ethtool_ops sume_uam_ethtool_ops = {
	.get_drvinfo = sume_uam_get_drvinfo,
};

void sume_uam_set_ethtool_ops(struct net_device *netdev)
{
	netdev->ethtool_ops = &sume_uam_ethtool_ops;
}
