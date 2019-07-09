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
  
  # to run the task on the production database if both prod and dev bases are present
  # RACK_ENV=production bundle exec rake storage:s3_migrate
  desc "migration from paperclip to active storage - amazon s3 files"
  task s3_migrate: :environment do
    path=ENV.fetch('AWS_URL')
    Asset.where.not(uploaded_file_file_name: nil).find_each do |f|
      doc = CGI.escape(f.uploaded_file_file_name)
      # this requires a public access to your S3 file
      # implement the expiring_url ?
      url = "https://#{path}/forge/attachments/#{f.id}/#{doc}"
      puts("file is #{f.uploaded_file_file_name} and url is #{url}")
      #url = f.uploaded_file.expiring_url(60)
      f.uploaded_file.attach(io: open(url),
                             filename: f.uploaded_file_file_name,
                             content_type: f.uploaded_file_content_type)
    end
  end
  
  # this is designed to transfer paperclip local files to the storage_production folder
  # if using active storage default parameter, "storage_production" should be changed to "storage"
  desc "migration from paperclip to active storage - local file system"
  task local_migrate: :environment do
    ActiveStorage::Attachment.find_each do |attachment|
      name = attachment.name
      source = attachment.record.send(name).path
      dest_dir = File.join(
        "storage_production",
        attachment.blob.key.first(2),
        attachment.blob.key.first(4).last(2))
      dest = File.join(dest_dir, attachment.blob.key)
      FileUtils.mkdir_p(dest_dir)
      puts "Moving #{source} to #{dest}"
      FileUtils.cp(source, dest)
    end
  end

end

# this does not work if directories were created by root
#files = Dir["#{x}/*"]
#if (files.size == 0)
#  FileUtils.rm_rf(x)
#end
