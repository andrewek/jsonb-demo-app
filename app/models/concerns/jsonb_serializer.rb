class JsonbSerializer
  def self.dump(hsh)
    hsh.to_json
  end

  def self.load(hsh)
    (hsh || {}).with_indifferent_access
  end
end
