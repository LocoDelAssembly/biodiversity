# encoding: utf-8

#NOTE: this spec needs compiled treetop files.

describe ScientificNameParser do
  before(:all) do
    set_parser(ScientificNameParser.new)
  end

  it "returns version number" do
    expect(ScientificNameParser.version).to match /^\d+\.\d+\.\d+/
  end

  it "fixes cases" do
    names = [
      ["QUERCUS ALBA", "Quercus alba"],
      ["QUERCUS (QUERCUS) ALBA", "Quercus (Quercus) alba"],
      ["QÜERCUS", "Qüercus"],
      ["PARDOSA MOéSTA", "Pardosa moésta"],
    ]
    names.each do |name, capitalization|
      expect(ScientificNameParser::fix_case(name)).to eq capitalization
    end
  end

  it "generates standardized json" do
    read_test_file do |y|
      expect(JSON.load(json(y[:name]))).to eq JSON.
        load(y[:jsn]) unless y[:comment]
    end
  end


  # it "generates new test_file" do
  #   new_test = open(File.expand_path(dir +
  #                    "../../spec/parser/test_data_new.txt"),"w")
  #   read_test_file do |y|
  #     if y[:comment]
  #       new_test.write y[:comment]
  #     else
  #       name = y[:name]
  #       jsn = json(y[:name])# rescue puts(y[:name])
  #       new_test.write("#{name}|#{jsn}\n")
  #     end
  #   end
  # end

  it "generates reasonable output if parser failed" do
    sn = "ddd sljlkj 3223452432"
    expect(json(sn)).to eq "{\"scientificName\":" \
      "{\"id\":\"3ebf93d9-b62a-5198-8715-4c8302f0a5d7\",\"parsed\":false," \
      "\"parser_version\":\"test_version\"," \
      "\"verbatim\":\"ddd sljlkj 3223452432\"}}"
  end

  it "shows version when the flag :show_version set to true" do
    expect(parse("Homo sapiens")[:scientificName][:parser_version]).
      to_not be_nil
  end

  it "shows version for not spelled names" do
    expect(parse("not_a_name")[:scientificName][:parser_version]).to_not be_nil
  end

  it "generates version for viruses" do
    expect(parse("Nile virus")[:scientificName][:parser_version]).to_not be_nil
  end
end

describe "ScientificNameParser with ranked canonicals" do
  before(:all) do
    @parser = ScientificNameParser.new(canonical_with_rank: true)
  end

  it "does not influence output for uninomials and binomials" do
    data = [
      ["Ekbainacanthus Yakowlew 1902","Ekbainacanthus"],
      ["Ekboarmia sagnesi herrerai Exposito 2007",
       "Ekboarmia sagnesi herrerai"],
      ["Ekboarmia holli Oberthür", "Ekboarmia holli"]]

    data.each do |d|
      parsed = @parser.parse(d[0])[:scientificName][:canonical]
      expect(parsed).to eq d[1]
    end
  end

  it "preserves rank for ranked multinomials" do
    data = [
      ["Cola cordifolia var. puberula A. Chev.",
       "Cola cordifolia var. puberula"],
      ["Abies homolepis forma umbilicata (Mayr) Schelle",
       "Abies homolepis forma umbilicata"],
      ["Quercus ilex ssp. ballota (Desf.) Samp",
       "Quercus ilex ssp. ballota"],
      ["Physarum globuliferum forma. flavum Leontyev & Dudka",
       "Physarum globuliferum forma. flavum"]
    ]
    data.each do |d|
      parsed = @parser.parse(d[0])[:scientificName][:canonical]
      expect(parsed).to eq d[1]
    end
  end
end

describe ".add_rank_to_canonical" do
  subject(:parser) { ScientificNameParser.new }

  it "adds rank to infraspecies with rank" do
    data = [
      ["Cola cordifolia var. puberula A. Chev.",
       "Cola cordifolia puberula",
       "Cola cordifolia var. puberula"],
      ["Abies homolepis forma umbilicata (Mayr) Schelle",
       "Abies homolepis umbilicata",
       "Abies homolepis forma umbilicata"],
      ["Quercus ilex ssp. ballota (Desf.) Samp",
       "Quercus ilex ballota",
       "Quercus ilex ssp. ballota"],
      ["Physarum globuliferum forma. flavum Leontyev & Dudka",
       "Physarum globuliferum flavum",
       "Physarum globuliferum forma. flavum"]
    ]
    data.each do |d|
      parsed = parser.parse(d[0])
      canonical1 = parsed[:scientificName][:canonical]
      expect(canonical1).to eq d[1]
      ScientificNameParser.add_rank_to_canonical(parsed)
      canonical2 = parsed[:scientificName][:canonical]
      expect(canonical2).to eq d[2]
    end
  end

  it "returns preprocessing tail if it exists" do
    sn = "Stenometope laevissimus sensu Eschmeyer 2004"
    res = parser.parse(sn)
    expect(res).to_not be_nil
    expect(res[:scientificName][:tail]).to eq "sensu Eschmeyer 2004"
  end

  it "does not work for hybrids yet" do
    data = [["Corda X cordiflora var. puberula",
            "Corda cordiflora puberula"]]
    data.each do |d|
      parsed = parser.parse(d[0])
      canonical1 = parsed[:scientificName][:canonical]
      expect(canonical1).to eq d[1]
      ScientificNameParser.add_rank_to_canonical(parsed)
      canonical2 = parsed[:scientificName][:canonical]
      expect(canonical2).to eq d[1]
    end
  end
end

describe ParallelParser do
  it "finds number of cpus" do
    pparser = ParallelParser.new
    expect(pparser.cpu_num).to be > 0
  end

  it "parses several names in parallel" do
    names = []
    read_test_file { |n| names << (n[:name]) if n[:name] }
    names.uniq!
    pparser = ParallelParser.new
    res = pparser.parse(names)
    expect(names.size).to be > 100
    expect(res.keys.size).to eq names.size
  end

  it "parses several names in parallel with given num of processes" do
    names = []
    read_test_file { |n| names << (n[:name]) if n[:name] }
    names.uniq!
    pparser = ParallelParser.new(4)
    res = pparser.parse(names)
    expect(names.size).to be > 100
    expect(res.keys.size).to eq names.size
  end

  it "has parsed name in native ruby format and in returned as \
      a hash with name as a key and parsed data as value" do
    names = []
    read_test_file { |n| names << (n[:name]) if n[:name] }
    names.uniq!
    pparser = ParallelParser.new(4)
    res = pparser.parse(names)
    names.each_with_index do |name, i|
      expect(res[name].is_a?(Hash)).to be true
      expect(res[name][:scientificName][:verbatim]).to eq name
    end
  end
end
