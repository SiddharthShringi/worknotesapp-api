json.id export.id
json.status export.status
json.error_message export.error_message
json.download_url(
  if export.completed? && export.pdf_attached?
    rails_blob_url(export.pdf, disposition: "attachment")
  else
    nil
  end
)
