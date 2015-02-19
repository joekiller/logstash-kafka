require 'maven/ruby/tasks'
require 'jar_installer'

task :default

desc 'setup jar dependencies to be used for "testing" and generates jruby-kafka_jars.rb'
task :setup do
  Jars::JarInstaller.install_jars
end

task :jar do
  Maven::Ruby::Maven.new.exec 'prepare-package'
end