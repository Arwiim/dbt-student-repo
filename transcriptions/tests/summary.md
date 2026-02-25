LEARNING OBJECTIVES
● Understand Unit Tests and Data Tests
● Understand how these tests can be defined
● Configure built-in generic Data Tests
● Create your own singular Data Tests
● Create Unit Tests for your data
TESTS OVERVIEW
● dbt has two types of tests: Unit Tests and Data Tests and it supports
Contracts
● Unit Tests test transformations with a small sample of mock data you provide
● Data Tests test data integrity and quality on the actual data
● Contracts enforce the schema of models
(such as column names, types and constraints)
DATA TESTS OVERVIEW
● There are two types of data tests: singular and generic
● There are four built-in generic tests:
○ unique
○ not_null
○ accepted_values
○ Relationships
● Singular data tests are SQL queries stored in tests which are expected to return an empty result set
● You can define your own custom generic tests
● You can import tests from dbt packages (will discuss later)
GUIDED EXERCISE

TEST dim_hosts_cleansed
Create a generic data test for the dim_hosts_cleansed model.
● host_id: Unique values, no nulls
● host_name shouldn’t contain any null values
● Is_superhost should only contain the values t and f.
● Execute `dbt test` to verify that your tests are passing
● Bonus: Figure out which tests to write for `fct_reviews` and implement
them
(You can find the solution among the resources)