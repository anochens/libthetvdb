require 'helper'

class TestLibthetvdb < Test::Unit::TestCase
	should "use break_array correctly" do
		actor_string = "|actor1|actor2|"

		broken = Thetvdb.break_array actor_string

		assert_equal 2, broken.length
		assert_equal ["actor1","actor2"], broken
	end

	should "use extractElemFromArray correctly" do
		arr = ["value"]

		new = Thetvdb.extractElemFromArray arr
		assert_equal "value", new
	end 
	
	should "make sure extractElemFromArray doesn't corrupt things" do
		arr = "value"

		new = Thetvdb.extractElemFromArray arr
		assert_equal "value", new
	end

	should "make sure break_array always returns an array" do
		actor_string = "actor1"

		broken = Thetvdb.break_array actor_string

		assert broken.is_a? Array
		assert_equal 1, broken.length
		assert_equal ["actor1"], broken 
	end
end

