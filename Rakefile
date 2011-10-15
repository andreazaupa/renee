ROOT = File.expand_path(File.dirname(__FILE__))

task :default => :test

renee_gems = %w[
  renee-core
  renee-render
  renee
].freeze

renee_gems_tasks = Hash[renee_gems.map{|rg| [rg, :"test_#{rg.gsub('-', '_')}"]}].freeze

desc "Run tests for all padrino stack gems"
task :test => renee_gems_tasks.values

renee_gems_tasks.each do |g, tn|
  desc "Run tests for #{g}"
  task tn do
    sh "cd #{File.join(ROOT, g)} && #{Gem.ruby} -S rake test"
  end
end

desc "Generate documentation for the Padrino framework"
task :doc do
  renee_gems.each do |name|
    sh "cd #{File.join(ROOT, name.to_s)} && #{Gem.ruby} -S rake doc"
  end
end