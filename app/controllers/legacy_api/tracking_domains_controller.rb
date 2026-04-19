# frozen_string_literal: true

module LegacyAPI
  class TrackingDomainsController < BaseController

    # Create a tracking domain on the current server.
    #
    #   URL:        /api/v1/tracking_domains/create
    #
    #   Parameters: name          => REQ: The subdomain prefix (e.g. "track")
    #               domain_id     => REQ: The integer ID of the parent domain
    #               track_clicks  => OPT: boolean (default: true)
    #               track_loads   => OPT: boolean (default: true)
    #               ssl_enabled   => OPT: boolean (default: true)
    #
    #   Response:   id            - integer tracking domain ID
    #               uuid          - tracking domain UUID
    #               name          - subdomain prefix
    #               full_name     - fully-qualified tracking hostname
    #               domain_id     - parent domain ID
    #               track_clicks  - boolean
    #               track_loads   - boolean
    #               ssl_enabled   - boolean
    #               dns_status    - "OK", "Missing", or "Invalid"
    #               dns_error     - error message or null
    #
    def create
      name      = api_params["name"].to_s.strip.downcase
      domain_id = api_params["domain_id"].to_s.strip

      if name.blank?
        render_parameter_error "`name` parameter is required but is missing"
        return
      end

      if domain_id.blank?
        render_parameter_error "`domain_id` parameter is required but is missing"
        return
      end

      domain = @current_credential.server.domains.find_by(id: domain_id)

      if domain.nil?
        render_error "DomainNotFound", message: "No domain with id #{domain_id} found on this server."
        return
      end

      track_domain = @current_credential.server.track_domains.new(
        name: name,
        domain: domain,
        track_clicks: api_params.key?("track_clicks") ? api_params["track_clicks"] : true,
        track_loads:  api_params.key?("track_loads")  ? api_params["track_loads"]  : true,
        ssl_enabled:  api_params.key?("ssl_enabled")  ? api_params["ssl_enabled"]  : true
      )

      unless track_domain.save
        render_error "ValidationError", message: track_domain.errors.full_messages.to_sentence
        return
      end

      render_success tracking_domain_data(track_domain)
    end

    # Check DNS status for a tracking domain.
    #
    #   URL:        /api/v1/tracking_domains/check
    #
    #   Parameters: id  => REQ: The integer ID of the tracking domain to check
    #
    #   Response:   id         - integer tracking domain ID
    #               full_name  - fully-qualified tracking hostname
    #               dns_status - "OK", "Missing", or "Invalid"
    #               dns_error  - error message or null
    #               dns_ok     - true if CNAME resolves correctly
    #
    def check
      id = api_params["id"].to_s.strip

      if id.blank?
        render_parameter_error "`id` parameter is required but is missing"
        return
      end

      track_domain = @current_credential.server.track_domains.find_by(id: id)

      if track_domain.nil?
        render_error "TrackingDomainNotFound", message: "No tracking domain with id #{id} found on this server."
        return
      end

      track_domain.check_dns

      render_success(
        id:         track_domain.id,
        full_name:  track_domain.full_name,
        dns_status: track_domain.dns_status,
        dns_error:  track_domain.dns_error,
        dns_ok:     track_domain.dns_ok?
      )
    end

    # Delete a tracking domain from the current server.
    #
    #   URL:        /api/v1/tracking_domains/delete
    #
    #   Parameters: id  => REQ: The integer ID of the tracking domain to delete
    #
    #   Response:   id        - integer ID of the deleted tracking domain
    #               full_name - fully-qualified tracking hostname
    #
    def delete
      id = api_params["id"].to_s.strip

      if id.blank?
        render_parameter_error "`id` parameter is required but is missing"
        return
      end

      track_domain = @current_credential.server.track_domains.find_by(id: id)

      if track_domain.nil?
        render_error "TrackingDomainNotFound", message: "No tracking domain with id #{id} found on this server."
        return
      end

      track_domain.destroy
      render_success id: track_domain.id, full_name: track_domain.full_name
    end

    private

    def tracking_domain_data(td)
      {
        id:           td.id,
        uuid:         td.uuid,
        name:         td.name,
        full_name:    td.full_name,
        domain_id:    td.domain_id,
        track_clicks: td.track_clicks,
        track_loads:  td.track_loads,
        ssl_enabled:  td.ssl_enabled,
        dns_status:   td.dns_status,
        dns_error:    td.dns_error
      }
    end

  end
end
