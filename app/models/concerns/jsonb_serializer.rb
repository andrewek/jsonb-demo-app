class JsonbSerializer
  def self.dump(hsh)
    hsh
  end

  def self.load(hsh)
    (hsh || {}).with_indifferent_access
  end
end
