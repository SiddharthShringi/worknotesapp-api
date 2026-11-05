json.id export.id
json.status export.status
json.error_message export.error_message
json.download_url(
  if export.completed? && export.file_attached?
    rails_blob_url(export.file, disposition: "attachment")
  else
    nil
  end
)
