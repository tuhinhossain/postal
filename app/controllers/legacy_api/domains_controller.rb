# frozen_string_literal: true

module LegacyAPI
  class DomainsController < BaseController

    # Create a domain on the current server and return its DKIM configuration.
    #
    #   URL:        /api/v1/domains/create
    #
    #   Parameters: name  => REQ: The domain name to register (e.g. "example.com")
    #
    #   Response:   id               - integer domain ID
    #               uuid             - domain UUID
    #               name             - domain name
    #               dkim_selector    - DKIM TXT record name  (e.g. "postal-ABCDEF._domainkey")
    #               dkim_public_key  - base64-encoded RSA public key (no PEM headers)
    #               dkim_record      - full DKIM TXT record value
    #               spf_record       - recommended SPF record value
    #               return_path_domain - return-path hostname to add as CNAME
    #
    def create
      name = api_params["name"].to_s.strip.downcase

      if name.blank?
        render_parameter_error "`name` parameter is required but is missing"
        return
      end

      domain = @current_credential.server.domains.new(
        name: name,
        verification_method: "DNS"
      )

      unless domain.save
        render_error "ValidationError", message: domain.errors.full_messages.to_sentence
        return
      end

      render_success domain_data(domain)
    end

    # Delete a domain from the current server.
    #
    #   URL:        /api/v1/domains/delete
    #
    #   Parameters: id  => REQ: The integer ID of the domain to delete
    #
    #   Response:   id   - integer ID of the deleted domain
    #               name - domain name
    #
    def delete
      id = api_params["id"].to_s.strip

      if id.blank?
        render_parameter_error "`id` parameter is required but is missing"
        return
      end

      domain = @current_credential.server.domains.find_by(id: id)

      if domain.nil?
        render_error "DomainNotFound", message: "No domain with id #{id} found on this server."
        return
      end

      domain.destroy
      render_success id: domain.id, name: domain.name
    end

    private

    def domain_data(domain)
      public_key = domain.dkim_key&.public_key&.to_s
                         &.gsub(/-+[A-Z ]+-+\n/, "")
                         &.gsub(/\n/, "")

      {
        id: domain.id,
        uuid: domain.uuid,
        name: domain.name,
        dkim_selector: domain.dkim_record_name,
        dkim_public_key: public_key,
        dkim_record: domain.dkim_record,
        spf_record: domain.spf_record,
        return_path_domain: domain.return_path_domain
      }
    end

  end
end
