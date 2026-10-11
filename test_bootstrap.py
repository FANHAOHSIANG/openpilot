"""Exercise download and handoff without touching /data or using the network."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('launch_openpilot.sh').read_text()
MOCK_GIT = '''#!/usr/bin/env python3
import os, sys
from pathlib import Path
a=sys.argv[1:]
mode=os.environ['CASE']
if a[0]=='clone':
 if mode=='download_failure': sys.exit(1)
 p=Path(a[-1])
 files=['launch_openpilot.sh','launch_chffrplus.sh','openpilot/selfdrive/controls/lib/carrot_dec.py','openpilot/selfdrive/modeld/jetlink/parked.py']
 for f in files:
  if mode=='missing_file' and f.endswith('parked.py'): continue
  q=p/f; q.parent.mkdir(parents=True,exist_ok=True); q.write_text('')
 (p/'launch_openpilot.sh').write_text('#!/bin/bash\\necho FEATURE_STARTED\\n')
 if mode=='vehicle_started': (Path(os.environ['TEST_DATA'])/'params/d/IsOnroad').write_text('1')
elif 'merge-base' in a and mode=='wrong_history': sys.exit(1)
elif 'submodule' in a and mode=='bad_submodule': print('-bad missing')
'''

class BootstrapTests(unittest.TestCase):
 def run_case(self, case, expect_success=False):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp); data=root/'data'; current=data/'openpilot'
   current.mkdir(parents=True); (current/'bootstrap-marker').touch()
   params=data/'params/d'; params.mkdir(parents=True)
   (params/'IsOnroad').write_text('1' if case=='onroad' else '0')
   script=current/'launch_openpilot.sh'
   script.write_text(SCRIPT.replace('readonly DATA=/data',f'readonly DATA={data}'))
   binpath=root/'bin'; binpath.mkdir()
   git=binpath/'git'; git.write_text(MOCK_GIT); git.chmod(0o755)
   env=dict(os.environ,PATH=str(binpath)+':'+os.environ['PATH'],CASE=case,TEST_DATA=str(data))
   result=subprocess.run(['bash',str(script)],cwd=current,env=env,capture_output=True,text=True)
   self.assertEqual(result.returncode==0,expect_success,result.stdout+result.stderr)
   self.assertEqual((current/'bootstrap-marker').exists(),not expect_success)
   self.assertEqual(len(list(data.glob('carrot-dec-install.*'))),int(case!='onroad')) # lock only
   self.assertEqual(len(list(data.glob('carrot-dec-bootstrap.*'))),int(expect_success))
   if expect_success: self.assertIn('FEATURE_STARTED',result.stdout)
 def test_success(self): self.run_case('success',True)
 def test_download_failure(self): self.run_case('download_failure')
 def test_wrong_history(self): self.run_case('wrong_history')
 def test_missing_file(self): self.run_case('missing_file')
 def test_bad_submodule(self): self.run_case('bad_submodule')
 def test_onroad(self): self.run_case('onroad')
 def test_vehicle_started(self): self.run_case('vehicle_started')

if __name__=='__main__': unittest.main()
