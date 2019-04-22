module Identikey
  class Administration

    class Digipass
      def self.find(session_id:, serial_no:)
        client = Identikey::Administration.new

        stat, digipass, error =
          client.digipass_execute_VIEW(
            session_id: session_id, serial_no: serial_no)

        if stat != 'STAT_SUCCESS'
          raise Identikey::Error, "Find digipass failed: #{stat} - #{error}"
        end

        new(
          serial:             digipass['DIGIPASSFLD_SERNO'],
          domain:             digipass['DIGIPASSFLD_DOMAIN'],
          ou:                 digipass['DIGIPASSFLD_ORGANIZATIONAL_UNIT'],
          type:               digipass['DIGIPASSFLD_DPTYPE'],
          application:        digipass['DIGIPASSFLD_ACTIVE_APPL_NAMES'],
          status:             digipass['DIGIPASSFLD_ASSIGN_STATUS'],
          userid:             digipass['DIGIPASSFLD_ASSIGNED_USERID'],
          assigned_at:        digipass['DIGIPASSFLD_ASSIGNED_DATE'],
          grace_expires_at:   digipass['DIGIPASSFLD_GRACE_PERIOD_EXPIRES'],
          created_at:         digipass['DIGIPASSFLD_CREATE_TIME'],
          updated_at:         digipass['DIGIPASSFLD_MODIFY_TIME'],
          activation_count:   digipass['DIGIPASSFLD_ACTIV_COUNT'],
          last_activation_at: digipass['DIGIPASSFLD_LAST_ACTIV_TIME'],
          bind_status:        digipass['DIGIPASSFLD_BIND_STATUS'],
          max_activations:    digipass['DIGIPASSFLD_MAX_ACTIVATIONS'],
          expired:            digipass['DIGIPASSFLD_EXPIRED'],
          grace_expired:      digipass['DIGIPASSFLD_GRACE_PERIOD_EXPIRED']
        )
      end

      def initialize(attributes)
        @attributes = attributes.freeze
      end

      def method_missing(name, *args, &block)
        if @attributes.key?(name)
          @attributes.fetch(name)
        else
          super(name, *args, &block)
        end
      end
    end

  end
end
