describe Object do
  subject { Object.new }

  it { should respond_to(:present?) }
  it { should respond_to(:with_options) }
end

describe String do
  subject { "rake db:migrate spec" }

  it { should respond_to(:present?) }
end

describe Hash do
  subject { {:foo => :bar} }
  it { should respond_to(:reverse_merge) }
  it { should respond_to(:deep_merge) }
  it { should respond_to(:with_indifferent_access) }
end
