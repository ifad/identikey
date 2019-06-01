module Identikey
  class Administration < Base

    class Digipass
      def self.find(session:, serial_no:)
        new(session).find(serial_no)
      end

      def initialize(session, digipass = nil)
        @session = session

        replace(digipass) if digipass
      end

      def replace(digipass)
        @attributes = {
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
        }.freeze

        self
      end

      def assigned?
        self.status == 'Assigned'
      end

      def find(serial_no)
        stat, digipass, error = @session.execute(
          :digipass_execute_VIEW, serial_no: serial_no)

        if stat != 'STAT_SUCCESS'
          raise Identikey::NotFound, "Find digipass failed: #{stat} - #{error}"
        end

        replace(digipass)
      end

      def reload
        find(self.serial)
      end

      def unassign!
        stat, digipass, error = @session.execute(
          :digipass_execute_UNASSIGN, serial_no: self.serial)

        if stat != 'STAT_SUCCESS'
          raise Identikey::OperationFailed, "Assign digipass failed: #{stat} - #{error}"
        end

        replace(digipass)
      end

      def assign!(username, domain)
        stat, digipass, error = @session.execute(
          :digipass_execute_ASSIGN, serial_no: self.serial, username: username, domain: domain)

        if stat != 'STAT_SUCCESS'
          raise Identikey::OperationFailed, "Unassign digipass failed: #{stat} - #{error}"
        end

        replace(digipass)
      end

      def test_otp(otp)
        stat, appl, error = @session.execute(
          :digipassappl_execute_TEST_OTP, serial_no: self.serial, appl: self.application, otp: otp)

        # Stat is useless here - it reports whether the call or not has
        # succeeded, not whether the OTP is valid
        if stat != 'STAT_SUCCESS'
          raise Identikey::OperationFailed, "Test OTP failed: #{stat} - #{error}"
        end

        appl['DIGIPASSAPPLFLD_RESULT_CODE'] == '0'
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
