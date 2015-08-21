
module Sof::Checks
class CheckMock < Sof::Check

  def initialize(check)
    super(check)
  end
  def run(server)
    { 'title' =>  {'exit status' => '0', 'status' => 'success'} }
  end
end
end
