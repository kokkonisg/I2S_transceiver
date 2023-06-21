

#############################################################
# Work directory
#############################################################
set_db init_hdl_search_path .
set_db script_search_path .

#############################################################
# Libraries setup
#############################################################
if { [catch {set path_target_library $::env(SYNTH_PATH_LIB) }]} {
    puts stderr "***********************************************************"
    puts stderr "Please set the SYNTH_PATH_LIB env to the path where your target .lib library exists"
    puts stderr "***********************************************************"

    exit 1
}

set_db init_lib_search_path ${path_target_library}

#############################################################
# Settings
#############################################################

#Target library
set_db library  {gf40npksdst_tt1p1v25c.lib}

#############################################################
# Folders and Reporting
#############################################################
set REPORTS_DIR   ../genus_reports/reports
set RESULTS_DIR   ../genus_reports/netlist

file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}

puts "------------------------------------------------------------"
puts "Reports Folder    : ${REPORTS_DIR}"
puts "Results Folder    : ${RESULTS_DIR}"
puts "------------------------------------------------------------"

#############################################################
#Analyze & Elaborate
#############################################################
set top_module I2S_top

read_hdl -sv -f filelist.f
# set_db verification_directory ../genus_reports/fv
eval elaborate I2S_top

#Enable retiming
# set_db design:fp_invsqrt .retime true

# write_hdl > ${RESULTS_DIR}/I2S_structural.v

#############################################################
# Uniquify
#############################################################

#############################################################
# Link
#############################################################

#############################################################
# RTL clock gate identification
#############################################################

#############################################################
# Fix multiple port
#############################################################

#############################################################
# Constraints
#############################################################



#Adjust for positive slack at the end
#set_path_adjust -from [all_registers] -to [all_registers] -delay -300


#############################################################
# Optimization settings
#############################################################

set_db syn_generic_effort high 
#none/low/medium/high/express 
#Default: medium 

set_db syn_map_effort high 
#none/low/medium/high 
#Default: high

set_db syn_opt_effort high 
#none/low/medium/high/extreme 
#Default: high

#############################################################
# Clock gating configuration
#############################################################

#############################################################
# Disable DRC fixing on clock network
#############################################################

#############################################################
# Compile - Synthesis
#############################################################

#Generic Synthesis
syn_gen
#Mapping to target lib cells
syn_map
#Optimization
syn_opt

#############################################################
# Incremental compile - synthesis
#############################################################

syn_opt -incremental

#############################################################
# Area recovery (2 passes)
#############################################################

#############################################################
# Finalization
#############################################################

#############################################################
# Reporting 
#############################################################

# check_design > ${REPORTS_DIR}/check_design.rpt
# check_design -all > ${REPORTS_DIR}/check_design_detailed.rpt
report_qor > ${REPORTS_DIR}/report_qor.rpt
report_area -detail > ${REPORTS_DIR}/report_area_detailed.rpt
report_timing -nets -max_paths 100 > ${REPORTS_DIR}/report_timing.rpt
report_gates > ${REPORTS_DIR}/gates.rpt

#############################################################
# Writing outputs
#############################################################

# write_sdf > ${RESULTS_DIR}/script.sdf
# write_hdl > ${RESULTS_DIR}/netlist.v

quit
