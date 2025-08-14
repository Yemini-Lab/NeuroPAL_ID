% !!!!!!! Before running! !!!!!!!!
% Set file path for sample nwb file on line 32
%

function run_comprehensive_nwb_test()
    % COMPREHENSIVE_NWB_TEST - Tests ALL functionality in nwb.m helper
    %
    % This script tests:
    %   READ-ONLY TESTS (using existing file):
    %   - get_reader
    %   - get_metadata  
    %   - read (full and chunked)
    %   - find_main_series
    %
    %   WRITE TESTS (using temporary files):
    %   - create (new file creation)
    %   - write (data writing)
    %
    %   EDGE CASES:
    %   - Error handling
    %   - Different data types
    %   - Metadata handling

    clear classes;
    rehash;
    
    fprintf('=== COMPREHENSIVE NWB HELPER TEST SUITE ===\n\n');

    % Test configuration - UPDATED PATH
    % NOTE: The hardcoded path below is for read-only tests and must exist.
    % The write tests use a relative path for a temporary file.
    sample_nwb_file = 'nwb/file/path';
    test_nwb_file = fullfile(pwd, 'test_nwb_file.nwb'); % Use current working directory

    total_tests = 0;
    passed_tests = 0;
    
    try
        %% ===== READ-ONLY TESTS =====
        fprintf('📖 PART 1: READ-ONLY TESTS (using existing file)\n');
        fprintf('Using file: %s\n\n', sample_nwb_file);
        
        if ~exist(sample_nwb_file, 'file')
            error('Sample NWB file not found. Please check path.');
        end

        %% Test 1: get_reader
        fprintf('TEST 1: get_reader() method...\n');
        total_tests = total_tests + 1;
        try
            nwb_reader = DataHandling.Helpers.nwb.get_reader(sample_nwb_file);
            assert(isa(nwb_reader, 'NwbFile'), 'Reader not a valid NwbFile object');
            fprintf('  ✅ PASS: Reader object created successfully\n');
            passed_tests = passed_tests + 1;
        catch ME
            fprintf('  ❌ FAIL: %s\n', ME.message);
        end

        %% Test 2: get_metadata  
        fprintf('\nTEST 2: get_metadata() method...\n');
        total_tests = total_tests + 1;
        try
            metadata = DataHandling.Helpers.nwb.get_metadata(nwb_reader);
            assert(isstruct(metadata), 'Metadata not a struct');
            required_fields = {'nx', 'ny', 'nz', 'nc', 'nt', 'native_dims', 'dtype_str'};
            for field = required_fields
                assert(isfield(metadata, field{1}), 'Missing required field: %s', field{1});
            end
            fprintf('  ✅ PASS: Metadata extracted with all required fields\n');
            fprintf('    - Dimensions: [ny=%d, nx=%d, nz=%d, nc=%d, nt=%d]\n', ...
                metadata.ny, metadata.nx, metadata.nz, metadata.nc, metadata.nt);
            fprintf('    - Data type: %s\n', metadata.dtype_str);
            passed_tests = passed_tests + 1;
        catch ME
            fprintf('  ❌ FAIL: %s\n', ME.message);
        end

        %% Test 3: read() - full mode
        fprintf('\nTEST 3: read() method - full mode...\n');
        total_tests = total_tests + 1;
        try
            full_data = DataHandling.Helpers.nwb.read(nwb_reader, 'mode', 'full');
            assert(~isempty(full_data), 'No data returned');
            fprintf('  ✅ PASS: Full data read successful\n');
            fprintf('    - Size: %s\n', mat2str(size(full_data)));
            passed_tests = passed_tests + 1;
        catch ME
            fprintf('  ❌ FAIL: %s\n', ME.message);
        end

        %% Test 4: read() - chunked mode with fallback
        fprintf('\nTEST 4: read() method - chunked mode...\n');
        total_tests = total_tests + 1;
        try
            cursor = struct();
            cursor.y1 = 1; cursor.y2 = min(3, metadata.ny);
            cursor.x1 = 1; cursor.x2 = min(3, metadata.nx);  
            cursor.z1 = 1; cursor.z2 = min(2, metadata.nz);
            cursor.c1 = 1; cursor.c2 = min(2, metadata.nc);
            
            chunk_data = DataHandling.Helpers.nwb.read(nwb_reader, 'cursor', cursor, 'mode', 'chunk');
            assert(~isempty(chunk_data), 'No chunk data returned');
            fprintf('  ✅ PASS: Chunked data read successful (with fallback handling)\n');
            fprintf('    - Chunk size: %s\n', mat2str(size(chunk_data)));
            passed_tests = passed_tests + 1;
        catch ME
            fprintf('  ❌ FAIL: %s\n', ME.message);
        end

        %% Test 5: find_main_series (internal method)
        fprintf('\nTEST 5: find_main_series() method...\n');
        total_tests = total_tests + 1;
        try
            main_series = DataHandling.Helpers.nwb.find_main_series(nwb_reader);
            assert(~isempty(main_series), 'No main series found');
            fprintf('  ✅ PASS: Main series located successfully\n');
            fprintf('    - Series type: %s\n', class(main_series));
            passed_tests = passed_tests + 1;
        catch ME
            fprintf('  ❌ FAIL: %s\n', ME.message);
        end

        %% ===== WRITE TESTS =====
        fprintf('\n📝 PART 2: WRITE TESTS (using temporary files)\n\n');
        
        file_created = false; % Flag to track if the file was created

        %% Test 6: create() method
        fprintf('TEST 6: create() method...\n');
        total_tests = total_tests + 1;
        try
            % Clean up any existing test file
            if exist(test_nwb_file, 'file')
                delete(test_nwb_file);
            end
            
            % Create test parameters
            test_dims = [10, 15, 8, 2, 5]; % [ny, nx, nz, nc, nt]
            test_dtype = 'single';
            test_metadata = struct('experiment', 'test_run', 'subject_id', 'test_001');
            
            % Create new NWB file
            DataHandling.Helpers.nwb.create(test_nwb_file, test_dims, test_dtype, test_metadata);
            
            % Verify file was created
            assert(exist(test_nwb_file, 'file') ~= 0, 'NWB file was not created');
            
            % Verify file can be read
            test_reader = DataHandling.Helpers.nwb.get_reader(test_nwb_file);
            assert(isa(test_reader, 'NwbFile'), 'Created file cannot be read as NwbFile');
            
            fprintf('  ✅ PASS: NWB file created successfully\n');
            fprintf('    - File: %s\n', test_nwb_file);
            passed_tests = passed_tests + 1;
            file_created = true; % Set the flag to true
        catch ME
            fprintf('  ❌ FAIL: %s\n', ME.message);
        end

        %% Test 7: write() method
        fprintf('\nTEST 7: write() method...\n');
        total_tests = total_tests + 1;
        
        if file_created % Only run this test if the file was created successfully
            try
                % Create test data array matching the dimensions we used in create()
                test_array = rand(test_dims, test_dtype); % [ny, nx, nz, nc, nt]
                
                % Write data to the file
                DataHandling.Helpers.nwb.write(test_nwb_file, test_array);
                
                % Verify data was written by reading it back
                written_reader = DataHandling.Helpers.nwb.get_reader(test_nwb_file);
                read_back_data = DataHandling.Helpers.nwb.read(written_reader, 'mode', 'full');
                
                assert(~isempty(read_back_data), 'No data read back after writing');
                assert(isequal(size(read_back_data), size(test_array)), ...
                    'Written data size mismatch. Expected: %s, Got: %s', ...
                    mat2str(size(test_array)), mat2str(size(read_back_data)));
                
                % Check data values (allowing for small floating point differences)
                max_diff = max(abs(read_back_data(:) - test_array(:)));
                assert(max_diff < 1e-6, 'Written data values do not match original');
                
                fprintf('  ✅ PASS: Data written and verified successfully\n');
                fprintf('    - Array size: %s\n', mat2str(size(test_array)));
                fprintf('    - Max difference: %.2e\n', max_diff);
                passed_tests = passed_tests + 1;
            catch ME
                fprintf('  ❌ FAIL: %s\n', ME.message);
            end
        else
            fprintf('  ❌ FAIL: Skipped because the NWB file could not be created in Test 6.\n');
        end

        %% ===== ERROR HANDLING TESTS =====
        fprintf('\n🚨 PART 3: ERROR HANDLING TESTS\n\n');

        %% Test 8: get_reader with invalid file
        fprintf('TEST 8: Error handling - invalid file path...\n');
        total_tests = total_tests + 1;
        try
            try
                DataHandling.Helpers.nwb.get_reader('/nonexistent/path/file.nwb');
                fprintf('  ❌ FAIL: Should have thrown an error for nonexistent file\n');
            catch expected_error
                fprintf('  ✅ PASS: Correctly threw error for nonexistent file\n');
                fprintf('    - Error: %s\n', expected_error.message);
                passed_tests = passed_tests + 1;
            end
        catch ME
            fprintf('  ❌ FAIL: Unexpected error in error handling test: %s\n', ME.message);
        end

        %% Test 9: get_reader with non-NWB file  
        fprintf('\nTEST 9: Error handling - non-NWB file extension...\n');
        total_tests = total_tests + 1;
        try
            try
                DataHandling.Helpers.nwb.get_reader('/some/file.mat');
                fprintf('  ❌ FAIL: Should have thrown an error for non-NWB file\n');
            catch expected_error
                if contains(expected_error.message, 'Non-nwb file')
                    fprintf('  ✅ PASS: Correctly rejected non-NWB file extension\n');
                    passed_tests = passed_tests + 1;
                else
                    fprintf('  ❌ FAIL: Wrong error message: %s\n', expected_error.message);
                end
            end
        catch ME
            fprintf('  ❌ FAIL: Unexpected error: %s\n', ME.message);
        end

        %% Test 10: Metadata from string path (alternative input)
        fprintf('\nTEST 10: get_metadata() with file path instead of reader object...\n');
        total_tests = total_tests + 1;
        try
            metadata_from_path = DataHandling.Helpers.nwb.get_metadata(sample_nwb_file);
            assert(isstruct(metadata_from_path), 'Metadata not returned as struct');
            
            % Compare individual fields instead of using isequal (which can fail on struct field ordering)
            fields_to_compare = {'nx', 'ny', 'nz', 'nc', 'nt', 'dtype_str'};
            for field = fields_to_compare
                field_name = field{1};
                % Convert values to consistent types for comparison
                val_path = metadata_from_path.(field_name);
                val_reader = metadata.(field_name);
                
                % Handle different data types (double vs int vs char)
                if isnumeric(val_path) && isnumeric(val_reader)
                    if abs(double(val_path) - double(val_reader)) > 1e-10
                        error('Field %s differs: path=%g, reader=%g', field_name, double(val_path), double(val_reader));
                    end
                elseif ischar(val_path) && ischar(val_reader)
                    if ~strcmp(val_path, val_reader)
                        error('Field %s differs: path=%s, reader=%s', field_name, val_path, val_reader);
                    end
                elseif ~isequal(val_path, val_reader)
                    error('Field %s differs: path=%s, reader=%s', field_name, string(val_path), string(val_reader));
                end
            end
            
            fprintf('  ✅ PASS: Metadata extraction works with file path input\n');
            passed_tests = passed_tests + 1;
        catch ME
            fprintf('  ❌ FAIL: %s\n', ME.message);
        end

        %% ===== SUMMARY =====
        fprintf('\n%s\n', repmat('=', 1, 50));
        fprintf('📊 TEST SUMMARY\n');
        fprintf('%s\n', repmat('=', 1, 50));
        fprintf('Tests Passed: %d/%d (%.1f%%)\n', passed_tests, total_tests, (passed_tests/total_tests)*100);
        
        if passed_tests == total_tests
            fprintf('🎉 ALL TESTS PASSED! Your nwb.m helper is fully functional.\n');
        else
            fprintf('⚠️  Some tests failed. Review the failures above.\n');
        end
        
        fprintf('\nTested Methods:\n');
        fprintf('  ✓ get_reader()      - Create NWB reader objects\n');
        fprintf('  ✓ get_metadata()    - Extract file metadata\n'); 
        fprintf('  ✓ read()            - Read data (full & chunked)\n');
        fprintf('  ✓ find_main_series() - Locate main data series\n');
        fprintf('  ✓ create()          - Create new NWB files\n');
        fprintf('  ✓ write()           - Write data to files\n');
        fprintf('  ✓ Error handling    - Invalid inputs\n');

    catch ME
        fprintf('\n💥 CRITICAL TEST FAILURE\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        end
    end
    
    % Clean up
    if exist(test_nwb_file, 'file')
        try
            delete(test_nwb_file);
            fprintf('\n🧹 Cleanup: Temporary test file deleted.\n');
        catch
            fprintf('\n⚠️  Warning: Could not delete temporary test file: %s\n', test_nwb_file);
        end
    end
    
    fprintf('\n=== TEST SUITE COMPLETE ===\n');
end
