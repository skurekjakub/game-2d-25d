extends GdUnitTestSuite


func test_arithmetic() -> void:
	assert_int(1 + 1).is_equal(2)


func test_string_concat() -> void:
	assert_str("hello " + "world").is_equal("hello world")
