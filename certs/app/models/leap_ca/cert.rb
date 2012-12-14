#
# Model for certificates stored in CouchDB.
#
# This file must be loaded after Config has been loaded.
#

module LeapCA
  class Cert < CouchRest::Model::Base

# No config yet.    use_database LeapCA::Config.db_name
    use_database 'client_certificates'

    timestamps!

    property :key, String                          # the client private RSA key
    property :cert, String                         # the client x509 certificate, signed by the CA
    property :valid_until, Time                    # expiration time of the client certificate
    property :random, Float, :accessible => false  # used to help pick a random cert by the webapp

    validates :key, :presence => true
    validates :cert, :presence => true
    validates :random, :presence => true, :numericality => {:greater_than_or_equal_to => 0, :less_than => 1}

    design do
      view :by_random
    end

    class << self
      def sample
        self.by_random.startkey(rand).first || self.by_random.first
      end

      def pick_from_pool
        cert = self.sample
        raise RECORD_NOT_FOUND unless cert
        cert.destroy
        return cert
      rescue RESOURCE_NOT_FOUND
        retry if self.by_random.count > 0
        raise RECORD_NOT_FOUND
      end

    end

  end
end
