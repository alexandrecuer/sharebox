class AddAttachmentUploadedFileToAssets < ActiveRecord::Migration[5.1]
  def self.up
    change_table :assets do |t|
      t.attachment :uploaded_file
      add_index :assets, :user_id
    end
  end

  def self.down
    remove_attachment :assets, :uploaded_file
  end
end
