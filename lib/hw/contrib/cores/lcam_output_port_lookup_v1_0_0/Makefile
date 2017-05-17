
.PHONY: all
.PHONY: update
.PHONY: sim

all: clean
	vivado -mode batch -source lcam_output_port_lookup.tcl

update:
	unzip xapp1151_Param_CAM.zip
	bash ./scripts/run_update_lib.sh
	cp -f ./xapp1151_cam_v1_1/src/vhdl/*.vhd ./hdl/vhdl/cam/
	patch -p1 -d . < cam.patch

clean:
	rm -rf ip_*  vivado*.* *.xml xgui/ .Xil* *.*~ *.zip hdl/axi_lite_ipif/ *.wdb xsim* xe* we*

