class Evaluation < ApplicationRecord
  belongs_to :submission
  belongs_to :testcase
  enum result: {waiting: 0, correct: 1, wrong: 2, partial: 3, time_limit: 4, memory_limit: 5, crash: 6, unknown_error: 7}
end