require_dependency 'document'
module  RedmineCommet
  module  Patches
    module DocumentPatch
      def self.included(base)
        base.class_eval do
          after_save :send_data_to_commet

          def send_data_to_commet
            webhook = self.project.webhook_settings.where(send_document: true).first

            if webhook
              require 'net/http'
              url = webhook.url
              uri = URI(url)
              path = "#{Setting.plugin_redmine_commet[:redmine_domain]}#{Rails.application.routes.url_helpers.document_path(self)}"
              params= {title: self.title,
                       body: self.description,
                       url: path ,
                       createdAt: self.created_on,
                       type: 'Document'
              }
              http = Net::HTTP.new(uri.host, uri.port)
              res = http.post(uri.path, params.to_json, {'Content-Type' =>'application/json'})
              puts res.body
              if res.code == "200"
                return [true, res.code]
              else
                return [false, "Status for webhook: #{res.code}"]
              end
            end
            return [true, '']
          rescue StandardError=> e
            return [false, e.message]
          end
        end
      end
    end
  end
end
