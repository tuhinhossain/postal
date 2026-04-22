# frozen_string_literal: true

module Postal
  module MessageDB
    module Migrations
      class AddIndexToDeliveriesMessageIdStatus < Postal::MessageDB::Migration

        def up
          @database.query("ALTER TABLE `#{@database.database_name}`.`deliveries` ADD INDEX `on_message_id_status_timestamp` (`message_id`, `status`(8), `timestamp`) USING BTREE")
        end

      end
    end
  end
end
