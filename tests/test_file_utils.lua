-- test_file_utils.lua - Tests for file_utils.lua module

suite("file_utils")

test("format helpers return expected strings", function()
    package.loaded['lib.core.files'] = nil
    local file_utils = require('lib.core.files')

    assert_equal(file_utils.formatFileSize(1024), "1KB")
    assert_equal(file_utils.formatFileSize(1024 * 1024), "1.0MB")
    assert_equal(file_utils.formatLapTime(61000), "1:01.000")
    assert_equal(file_utils.formatLapTimeShort(61000), "1:01.00")
end)

test("CSV escaping and parsing handle quotes", function()
    package.loaded['lib.core.files'] = nil
    local file_utils = require('lib.core.files')

    local escaped = file_utils.escapeCSV('hello, "world"')
    assert_equal(escaped, '"hello, ""world"""')

    local fields = file_utils.parseCSVLine('"a","b,c","d""e"')
    assert_table_length(fields, 3)
    assert_equal(fields[1], "a")
    assert_equal(fields[2], "b,c")
    assert_equal(fields[3], 'd"e')
end)

test("scanCSVFiles finds legacy tracks files", function()
    local originalDir = __dirname
    __dirname = "tests/tmp_scan"
    package.loaded['lib.core.files'] = nil
    package.loaded['lib.core.paths'] = nil
    mock.resetVfs()
    local file_utils = require('lib.core.files')

    local originalDirExists = io.dirExists
    local originalScanDir = io.scanDir
    local originalFileSize = io.fileSize

    io.dirExists = function(path)
        return path == (__dirname .. "/tracks/")
    end
    io.scanDir = function(path, pattern)
        if path == (__dirname .. "/tracks/") then
            return { "sample.csv" }
        end
        return nil
    end
    io.fileSize = function(path)
        return 2048
    end

    local files = file_utils.scanCSVFiles("Test Track")
    assert_table_length(files, 1)
    assert_equal(files[1].filename, "sample.csv")
    assert_equal(files[1].source, "legacy")
    assert_equal(files[1].size, 2048)

    io.dirExists = originalDirExists
    io.scanDir = originalScanDir
    io.fileSize = originalFileSize
    __dirname = originalDir
end)
