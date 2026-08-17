function testResults = runAllTests()
% runAllTests Runs all automated tests for the Fluxion project

addpath(genpath(pwd));

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.DiagnosticsRecordingPlugin;

suite = TestSuite.fromFolder(fullfile(pwd, 'tests'));
runner = TestRunner.withTextOutput;
runner.addPlugin(DiagnosticsRecordingPlugin);

disp('Starting Fluxion test suite...');
testResults = runner.run(suite);

if all([testResults.Passed])
    disp('All tests passed successfully!');
else
    disp('Some tests failed. Check the results.');
end

end
