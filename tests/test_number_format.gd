extends GdUnitTestSuite


func test_compact_under_10k_renders_integer() -> void:
	assert_str(NumberFormat.compact(1234.0)).is_equal("1234")


func test_compact_thousands_renders_k() -> void:
	assert_str(NumberFormat.compact(12500.0)).is_equal("12.5k")


func test_compact_millions_renders_m() -> void:
	assert_str(NumberFormat.compact(1_234_000.0)).is_equal("1.2M")


func test_compact_zero() -> void:
	assert_str(NumberFormat.compact(0.0)).is_equal("0")


func test_compact_999_999_promotes_to_one_megs() -> void:
	assert_str(NumberFormat.compact(999_999.0)).is_equal("1.0M")
