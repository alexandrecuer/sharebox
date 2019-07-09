namespace :storage do
  
  # you have to launch :
  # - bundle exec rake storage:clean_storage['storage']
  # - bundle exec rake storage:clean_storage['storage_production']
  # to print the task list : bundle exec rake --tasks
  desc "cleans up empty directories in a specified folder - ONLY FOR LOCAL STORAGE"
  task :clean_storage, [:directory] do |task, args| 
    Dir.glob(Rails.root.join(args[:directory], '**', '*').to_s).sort_by(&:length).reverse.each do |x|
      puts("object is #{x}")
      if File.directory?(x) && Dir.empty?(x)
        %x[ sudo rm -Rf #{x} ]
      end
    end
  end

end

# this does not work if directories were created by root
#files = Dir["#{x}/*"]
#if (files.size == 0)
#  FileUtils.rm_rf(x)
#end