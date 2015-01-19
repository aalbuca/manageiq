module EmsRefresh
  module Parsers
    class Foreman
      def self.provisioning_inv_to_hashes(inv)
        new.provisioning_inv_to_hashes(inv)
      end

      def self.configuration_inv_to_hashes(inv, provisioning_manager)
        new.configuration_inv_to_hashes(inv, provisioning_manager)
      end

      def provisioning_inv_to_hashes(inv)
        result = {}
        ids = {}
        result[:customization_scripts] = customization_scripts_inv_to_hash(inv[:media], inv[:ptables])
        add_ids(ids, result[:customization_scripts])
        result[:operating_system_flavors] = operating_system_flavors_inv_to_hashes(inv[:operating_systems], ids)
        result
      end

      def configuration_inv_to_hashes(inv, provisioning_manager)
        result = {}
        ids = fetch_provisioning_manager_ids(provisioning_manager)
        result[:configuration_profiles] = configuration_profile_inv_to_hashes(inv[:hostgroups], ids)
        add_ids(ids, result[:configuration_profiles])
        result[:configured_systems] = configured_system_inv_to_hashes(inv[:hosts], ids)
        result
      end

      def media_inv_to_hashes(media)
        media.collect do |m|
          {
            "manager_ref" => "medium:#{m["id"]}",
            "type"        => "CustomizationScriptMedium",
            "name"        => m["name"]
          }
        end
      end

      def ptables_inv_to_hashes(ptables)
        ptables.collect do |m|
          {
            "manager_ref" => "ptable:#{m["id"]}",
            "type"        => "CustomizationScriptPtable",
            "name"        => m["name"]
          }
        end
      end

      def customization_scripts_inv_to_hash(media, ptables)
        media_inv_to_hashes(media) + ptables_inv_to_hashes(ptables)
      end

      def operating_system_flavors_inv_to_hashes(flavors_inv, ids)
        flavors_inv.collect do |os|
          {
            "manager_ref"           => "operating_system:#{os["id"]}",
            "name"                  => os["fullname"],
            "description"           => os["description"],
            "customization_scripts" => ids_lookup(ids, os["media"], "medium") + ids_lookup(ids, os["ptables"], "ptable")
          }
        end
      end

      def configuration_profile_inv_to_hashes(recs, ids)
        recs.collect do |profile|
          {
            "manager_ref"                    => "hostgroup:#{profile["id"]}",
            "name"                           => profile["name"],
            "description"                    => profile["title"],
            "operating_system_flavor_id"     => id_lookup(ids, profile, "operating_system", "operatingsystem_id"),
            "customization_script_ptable_id" => id_lookup(ids, profile, "ptable"),
            "customization_script_medium_id" => id_lookup(ids, profile, "medium"),
          }
        end
      end

      def configured_system_inv_to_hashes(recs, ids)
        recs.collect do |cs|
          {
            "manager_ref"                => "host:#{cs["id"]}",
            "hostname"                   => cs["name"],
            "configuration_profile"      => id_lookup(ids, cs, "hostgroup"),
            "operating_system_flavor_id" => id_lookup(ids, cs, "operating_system", "operatingsystem_id"),
          }
        end
      end

      private

      def fetch_provisioning_manager_ids(manager)
        ids = {}
        manager.customization_scripts.each { |cs| ids[cs.manager_ref] = cs.id }
        manager.operating_system_flavors.each { |cs| ids[cs.manager_ref] = cs.id }
        ids
      end

      def add_ids(target, recs, key = "manager_ref")
        recs.each { |r| target[r[key]] = r }
      end

      def id_lookup(ids, record, prefix, id_key = "#{prefix}_id")
        key = record[id_key]
        ids["#{prefix}:#{key}"] if key
      end

      def ids_lookup(ids, records, prefix, id_key = "id")
        records.collect { |record| id_lookup(ids, record, prefix, id_key) }
      end
    end
  end
end
