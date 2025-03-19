import os, sys
import subprocess
import multiprocessing
import signal
from glob import glob
from typing import Any, Callable

PROJECT_DIR = '.'
SIM_DIR = 'SIM'
SRC_DIR = 'Verilog'
WORKING_DIR = 'SIM'
COMMON_MODULE_LIST = ['cpu_tb', 'sky130_sram_2rw_32x128_32', 'sky130_sram_2rw_64x128_64']
SIM_CASE = {
    'simple_program': 'simpleprogram',
    'MULT1': 'mult1',
    'multiplication_support_MULT2' : 'mult2',
    'pipeline_basic_MULT2' : 'mult2',
    'pipeline_hazard_MULT3' : 'mult3',
    'pipeline_hazard_advanced_MULT4' : 'mult4'
}
DST_DIR = 'GROUP_X'

def run_sys_command(command: str, cwd: str = '.'):
    try:
        p = subprocess.Popen(command, shell=True, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, preexec_fn=os.setpgrp)
        _stdout, _stderr = p.communicate(timeout=22)
    except subprocess.TimeoutExpired as e:
        print(f'\t\033[1;31mTimeout for {command} expired.\033[0m')
        _stdout = e.stdout
        _stderr = e.stderr
        os.killpg(os.getpgid(p.pid), signal.SIGTERM)
    finally:
        return p.returncode, _stdout, _stderr

def run_sys_command_mp(f: Callable[[str, str], Any], command_list: list):
    _mp_results = []
    _pool = multiprocessing.Pool()
    for command in command_list:
        _mp_results.append(_pool.apply_async(f, args=(command,)))
    _pool.close()
    _pool.join()
    return _mp_results

def check_mp_sys_command(result_list: list):
    _cleared = True
    for _res in result_list:
        if _res.get()[0] != 0:
            print(f'\t--> {_res.get()[2]}')
            _cleared = False
    return _cleared

run_sys_command(f'rm -rf {PROJECT_DIR}/{DST_DIR} && mkdir -p {PROJECT_DIR}/{DST_DIR}/MULT4_content {PROJECT_DIR}/{DST_DIR}/RTL_SOLUTIONS {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/tmp_RTL')  
_command_list = []
_command_list.append(f'cp -rf {PROJECT_DIR}/{SRC_DIR}/RTL_SOLUTION* {PROJECT_DIR}/{DST_DIR}/RTL_SOLUTIONS/')
_command_list.append(f'cp -rf {PROJECT_DIR}/{SIM_DIR}/* {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/')
_command_list.append(f'cp -f {PROJECT_DIR}/{SRC_DIR}/cpu_tb.v {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/tmp_RTL/')
_command_list.append(f'cp -f {PROJECT_DIR}/{SRC_DIR}/sky130_sram_2rw.v {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/tmp_RTL/')
_command_list.append(f'cp -f {PROJECT_DIR}/{SIM_DIR}/data/testcode_m/mult4_imem_content.txt {PROJECT_DIR}/{DST_DIR}/MULT4_content/')
if not check_mp_sys_command(run_sys_command_mp(run_sys_command, _command_list)):
    print(f'\033[1;31mErrors occurred when creating the GROUP_X folder\033[0m. Please check your file structures.')
    raise IOError
    
scoreboard = []
for (src_case, test_mem_case) in SIM_CASE.items():
    print(f'\033[1;34mChecking {test_mem_case}->{src_case}\033[0m ...')
    ## Prepare simulation files
    _command_list = []
    _mp_results = []
    try:
        verilog_file_path = glob(f'{PROJECT_DIR}/{DST_DIR}/**/*{src_case}*/', recursive=True)[0]    
        _command_list.append(f'rm -f {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/data/dmem_content.txt && cp -f {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/data/testcode_m/{test_mem_case}_dmem_content.txt {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/data/dmem_content.txt')
        _command_list.append(f'rm -f {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/data/imem_content.txt && cp -f {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/data/testcode_m/{test_mem_case}_imem_content.txt {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/data/imem_content.txt')
        _command_list.append(f'rm -rf {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/tmp_RTL/tmp_SOLUTION && cp -r {verilog_file_path} {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/tmp_RTL/tmp_SOLUTION')
        _mp_results = run_sys_command_mp(run_sys_command, _command_list)
    except IndexError:
        print(f'\033[1;31mRTL_SOLUTION {src_case} folder is not found\033[0m. Please check your file structures.')
        scoreboard.append(False)
        continue
    
    if not check_mp_sys_command(_mp_results):
        print(f'\033[1;31mErrors occurred when setting mem_content files\033[0m. Please check your file structures.')
        scoreboard.append(False)
        continue
    else:
        verilog_files = glob(f'{PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/tmp_RTL/**/*.v', recursive=True)
        _rtl_path_relative = [file_name.split(f'{WORKING_DIR}/')[-1] for file_name in verilog_files]
        with open(f'{PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}/files_verilog.f', 'w') as f:
            for _rtl_path in _rtl_path_relative:
                f.write(f"./{_rtl_path}\n")

    ## Run simulation  
    _result = run_sys_command(f'source ./xcelium_23.03.rc && make all', cwd=f'{PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}')

    if _result[0] != 0:
        print(f'{_result[1]}\n{_result[2]}\n')
        print(f'\033[1;31mErrors occurred when simulating\033[0m. Please check your source code structure.')
        scoreboard.append(False)
        continue
    else:
        lines = _result[1].split('Generating native compiled code:')[-1]
        _common_module_integrity = True
        for common_module in COMMON_MODULE_LIST:
            if f'recompiling design unit worklib.{common_module}:v' in _result[1] or f'worklib.{common_module}:v' not in lines:
                print(f'\033[1;31mCommon module ({common_module}) redefinition is not allowed\033[0m. Please check your submission.')
                _common_module_integrity = False
        lines = _result[1].split('xcelium> run')[-1]
        if not _common_module_integrity:
            scoreboard.append(False)
            continue
        elif 'Debug info' in lines:
            for line in lines.splitlines():
                print(f'\t{line}')
            print(f'\033[1;31mSimulation result is incorrect\033[0m. Please check your design.')
            scoreboard.append(False)
            continue
        else:
            for line in lines.splitlines():
                if 'cycles' in line:
                    scoreboard.append(int(line.split(' cycles')[0]))
                   
run_sys_command(f'rm -rf {PROJECT_DIR}/{DST_DIR}/{WORKING_DIR}')
assert len(scoreboard) == len(SIM_CASE), f'\033[1;31mIncorrect amount of test scenarios ({len(scoreboard)}/{len(SIM_CASE)}).\033[0m'

print('\033[1;34mDone\nScoreboard:\n\033[0m')
if scoreboard[0] and scoreboard[1] and scoreboard[2] and scoreboard[3]:
    _score_1 = 0.5
else:
    _score_1 = 0.0
print(f'\033[1m\tFuntional pipelined MULT2:\t{round(_score_1, 1)} pts\033[0m ({scoreboard[0]} cc, {scoreboard[1]} cc, {scoreboard[2]} cc, {scoreboard[3]} cc)\n')
if scoreboard[4]:
    _score_2 = 0.5
else:
    _score_2 = 0.0
print(f'\033[1m\tFuntional pipelined MULT3:\t{round(_score_2, 1)} pts\033[0m ({scoreboard[4]} cc)\n')
if scoreboard[5]:
    _score_3 = 0.4
    if scoreboard[5] <= 828:
        _score_3 += 1.6
    elif scoreboard[5] <= 1636:
        _score_3 += 0.8
else:
    _score_3 = 0.0
print(f'\033[1m\tFuntional pipelined MULT4:\t{round(_score_3, 1)} pts\033[0m ({scoreboard[5]} cc)\n')
print('\t'+'-'*42)
print(f'\033[1m\tTotal Score:\t{round(_score_1+_score_2+_score_3, 1)} pts\n\033[0m')
        
print(f'\033[1;33mDo not forget to complete the {DST_DIR} folder before your submission!\n\033[0m')
        
