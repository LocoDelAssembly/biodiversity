# encoding: UTF-8
dir = File.dirname("__FILE__")
require 'rubygems'
require 'spec'
require 'treetop'

Treetop.load(File.expand_path(dir + '../../lib/biodiversity/parser/scientific_name'))

describe ScientificName do
  before(:all) do
    @parser = ScientificNameParser.new 
  end
  
  def parse(input)
    @parser.parse(input)
  end
  
  def value(input)
    parse(input).value
  end
  
  def canonical(input)
    parse(input).canonical
  end
  
  def details(input)
    parse(input).details
  end
  
  it 'should parse uninomial' do
    sn = 'Pseudocercospora'
    parse(sn).should_not be_nil
    value(sn).should == 'Pseudocercospora'
    canonical(sn).should == 'Pseudocercospora'
    details(sn).should == {:uninomial=>"Pseudocercospora"}
  end
  
  it 'should parse canonical' do
    sn = 'Pseudocercospora     dendrobii'
    parse(sn).should_not be_nil
    value(sn).should == 'Pseudocercospora dendrobii'
    canonical(sn).should == 'Pseudocercospora dendrobii'
    details(sn).should == {:species=>"dendrobii", :genus=>"Pseudocercospora"}
  end
  
  it 'should parse subgenus ZOOLOGICAL' do
    sn = "Doriteuthis (Amerigo) pealeii Author 1999"
    parse(sn).should_not be_nil
    value(sn).should == "Doriteuthis (Amerigo) pealeii Author 1999"
    canonical(sn).should == "Doriteuthis pealeii"
    details(sn).should == {:subgenus=>"Amerigo", :authors=>{:year=>"1999", :names=>["Author"]}, :species=>"pealeii", :genus=>"Doriteuthis"}
  end
  
  it 'should parse æ in the name' do
    names = [
      ["Læptura laetifica Dow, 1913", "Laeptura laetifica Dow 1913"],
      ["Leptura lætifica Dow, 1913", "Leptura laetifica Dow 1913"],
      ["Leptura leætifica Dow, 1913", "Leptura leaetifica Dow 1913"],
      ["Leæptura laetifica Dow, 1913", "Leaeptura laetifica Dow 1913"],
      ["Leœptura laetifica Dow, 1913", "Leoeptura laetifica Dow 1913"]
    ]
    names.each do |name_pair|
      parse(name_pair[0]).should_not be_nil
      value(name_pair[0]).should == name_pair[1]
    end
  end

  it 'should parse year' do
    sn = "Platypus bicaudatulus Schedl 1935"
    parse(sn).should_not be_nil
    value(sn).should == "Platypus bicaudatulus Schedl 1935"
    sn = "Platypus bicaudatulus Schedl, 1935h"
    parse(sn).should_not be_nil
    value(sn).should == "Platypus bicaudatulus Schedl 1935"
    details(sn).should == {:genus=>"Platypus", :species=>"bicaudatulus", :authors=>{:names=>["Schedl"], :year=>"1935"}}
    parse("Platypus bicaudatulus Schedl, 1935B").should_not be_nil
  end
  
  it 'should parse species autonym for complex subspecies authorships' do
    parse("Aus bus Linn. var. bus").should_not be_nil
    details("Aus bus Linn. var. bus").should == {:species=>"bus", :species_authors=>{:authors=>{:names=>["Linn."]}}, :genus=>"Aus", :subspecies=>[{:rank=>"var.", :value=>"bus"}]}
    parse("Agalinis purpurea (L.) Briton var. borealis (Berg.) Peterson 1987").should_not be_nil
    details("Agalinis purpurea (L.) Briton var. borealis (Berg.) Peterson 1987").should == {:species=>"purpurea", :genus=>"Agalinis", :species_authors=>{:orig_authors=>{:names=>["L."]}, :authors=>{:names=>["Briton"]}}, :subspecies_authors=>{:orig_authors=>{:names=>["Berg."]}, :authors=>{:year=>"1987", :names=>["Peterson"]}}, :subspecies=>[{:value=>"borealis", :rank=>"var."}]}
  end
  
  it 'should parse several authors' do
    sn = "Pseudocercospora dendrobii U. Braun & Crous"
    parse(sn).should_not be_nil
    value(sn).should == "Pseudocercospora dendrobii U. Braun et Crous"
    canonical(sn).should == "Pseudocercospora dendrobii"
    details(sn).should == {
        :authors=>{:names=>["U. Braun","Crous"]},
        :species=>"dendrobii", 
        :genus=>"Pseudocercospora"}
    sn = "Pseudocercospora dendrobii U. Braun and Crous"
    parse(sn).should_not be_nil
    value(sn).should == "Pseudocercospora dendrobii U. Braun et Crous"
    sn = "Pseudocercospora dendrobii U. Braun et Crous"
    parse(sn).should_not be_nil
    value(sn).should == "Pseudocercospora dendrobii U. Braun et Crous"    
  end

  it 'should parse several authors with a year' do
    sn = "Pseudocercospora dendrobii U. Braun & Crous 2003"
    parse(sn).should_not be_nil
    value(sn).should == "Pseudocercospora dendrobii U. Braun et Crous 2003"
    canonical(sn).should == "Pseudocercospora dendrobii"
    details(sn).should == {
        :authors=>{:names=>["U. Braun","Crous"], :year => "2003"},
        :species=>"dendrobii", 
        :genus=>"Pseudocercospora"}
    sn = "Pseudocercospora dendrobii Crous, 2003"
    parse(sn).should_not be_nil
    parse("Zophosis persis (Chatanay, 1914)").should_not be_nil
    parse("Zophosis persis (Chatanay 1914)").should_not be_nil
    parse("Zophosis persis (Chatanay), 1914").should_not be_nil
    value("Zophosis persis (Chatanay), 1914").should == "Zophosis persis (Chatanay 1914)"
    details("Zophosis persis (Chatanay), 1914").should == {:genus=>"Zophosis", :species=>"persis", :orig_authors=>{:names=>["Chatanay"]}, :year=>"1914"}
    
    parse("Zophosis persis (Chatanay) 1914").should_not be_nil
    #parse("Zophosis persis Chatanay (1914)").should_not be_nil
  end  
  
  it 'should parse scientific name' do
    parse("Pseudocercospora dendrobii (H.C. Burnett) U. Braun & Crous 2003").should_not be_nil
    value("Pseudocercospora dendrobii(H.C.     Burnett)U. Braun & Crous     2003").should == "Pseudocercospora dendrobii (H.C. Burnett) U. Braun et Crous 2003"
    canonical("Pseudocercospora dendrobii(H.C.     Burnett)U. Braun & Crous     2003").should == "Pseudocercospora dendrobii"
    {:orig_authors=>{:names=>["H.C. Burnett"]}, :species=>"dendrobii", :authors=>{:year=>"2003", :names=>["U. Braun", "Crous"]}, :genus=>"Pseudocercospora"}
  
    parse("Stagonospora polyspora M.T. Lucas & Sousa da Câmara 1934").should_not be_nil
    value("Stagonospora polyspora M.T. Lucas & Sousa da Câmara 1934").should == "Stagonospora polyspora M.T. Lucas et Sousa da Câmara 1934"
    details("Stagonospora polyspora M.T. Lucas & Sousa da Câmara 1934").should == {:authors=>{:year=>"1934", :names=>["M.T. Lucas", "Sousa da C\303\242mara"]}, :species=>"polyspora", :genus=>"Stagonospora"}
    
    parse("Cladoniicola staurospora Diederich, van den Boom & Aptroot 2001").should_not be_nil
    parse("Yarrowia lipolytica var. lipolytica (Wick., Kurtzman & E.A. Herrm.) Van der Walt & Arx 1981").should_not be_nil
    value("Yarrowia lipolytica var. lipolytica (Wick., Kurtzman & E.A. Herrm.) Van der Walt & Arx 1981").should == "Yarrowia lipolytica var. lipolytica (Wick., Kurtzman et E.A. Herrm.) Van der Walt et Arx 1981"
    parse("Physalospora rubiginosa (Fr.) anon.").should_not be_nil
    parse("Pleurotus ëous (Berk.) Sacc. 1887").should_not be_nil
    parse("Lecanora wetmorei Śliwa 2004").should_not be_nil
    #   valid 
    #   infraspecific
    parse("Calicium furfuraceum * furfuraceum (L.) Pers. 1797").should_not be_nil
    parse("Exobasidium vaccinii ** andromedae (P. Karst.) P. Karst. 1882").should_not be_nil
    parse("Urceolaria scruposa **** clausa Flot. 1849").should_not be_nil
    parse("Cortinarius angulatus B gracilescens Fr. 1838").should_not be_nil
    parse("Cyathicula scelobelonium").should_not be_nil
    #   single quote that did not show
    #    parse("Phytophthora hedraiandra De Cock & Man in ?t Veld 2004"
    #   Phthora vastatrix d?Hérelle 1909
    #   author is exception
    parse("Tuber liui A S. Xu 1999").should_not be_nil
    parse("Agaricus squamula Berk. & M.A. Curtis 1860").should_not be_nil
    parse("Peltula coriacea Büdel, Henssen & Wessels 1986").should_not be_nil
    #had to add no dot rule for trinomials without a rank to make it to work
    parse("Saccharomyces drosophilae anon.").should_not be_nil
    details("Saccharomyces drosophilae anon.").should == {:genus=>"Saccharomyces", :species=>"drosophilae", :authors=>{:names=>["anon."]}}
  end
  
  it 'should parse several authors with several years' do
    parse("Pseudocercospora dendrobii (H.C. Burnett 1883) U. Braun & Crous 2003").should_not be_nil
    value("Pseudocercospora dendrobii(H.C.     Burnett1883)U. Braun & Crous     2003").should == "Pseudocercospora dendrobii (H.C. Burnett 1883) U. Braun et Crous 2003"
    canonical("Pseudocercospora dendrobii(H.C.     Burnett 1883)U. Braun & Crous     2003").should == "Pseudocercospora dendrobii"
    details("Pseudocercospora dendrobii(H.C.     Burnett 1883)U. Braun & Crous     2003").should == {:orig_authors=>{:year=>"1883", :names=>["H.C. Burnett"]}, :species=>"dendrobii", :authors=>{:year=>"2003", :names=>["U. Braun", "Crous"]}, :genus=>"Pseudocercospora"}
  end
  
  it 'should parse unknown original authors (auct.)/(hort.)/(?)' do
    parse("Tragacantha leporina (?) Kuntze").should_not be_nil
    value("Tragacantha    leporina (    ?      )       Kuntze").should == "Tragacantha leporina (?) Kuntze"
    parse("Lachenalia tricolor var. nelsonii (auct.) Baker").should_not be_nil
    value("Lachenalia tricolor var. nelsonii (  auct. ) Baker").should == "Lachenalia tricolor var. nelsonii (auct.) Baker"
    details("Lachenalia tricolor var. nelsonii (  auct. ) Baker").should == {:genus=>"Lachenalia", :species=>"tricolor", :subspecies=>[{:rank=>"var.", :value=>"nelsonii"}], :orig_authors=>"unknown", :authors=>{:names=>["Baker"]}}
  end
  
  it 'should parse unknown authors auct./anon./hort./ht.' do
    parse("Puya acris ht. ex Gentil").should_not be_nil
    
  end
  

  it 'should not parse serveral authors groups with several years NOT CORRECT' do
    parse("Pseudocercospora dendrobii (H.C. Burnett 1883) (Leight.) (Movss. 1967) U. Braun & Crous 2003").should be_nil
  end

    
  it 'should parse utf-8 name' do
    parse("Trematosphaeria phaeospora (E. Müll.) L. Holm 1957").should_not be_nil
    value("Trematosphaeria         phaeospora (  E.      Müll.       )L.       Holm     1957").should == "Trematosphaeria phaeospora (E. Müll.) L. Holm 1957"
    canonical("Trematosphaeria phaeospora(E. Müll.) L.       Holm 1957").should == "Trematosphaeria phaeospora"
    details("Trematosphaeria phaeospora(E. Müll.) L.       Holm 1957 ").should == {:orig_authors=>{:names=>["E. M\303\274ll."]}, :species=>"phaeospora", :authors=>{:year=>"1957", :names=>["L. Holm"]}, :genus=>"Trematosphaeria"} 
  end
  
  it "should parse name with var." do
    parse("Phaeographis inusta var. macularis (Leight.) A.L. Sm. 1861").should_not be_nil
    value("Phaeographis     inusta    var. macularis(Leight.)  A.L.       Sm.     1861").should == "Phaeographis inusta var. macularis (Leight.) A.L. Sm. 1861"
    canonical("Phaeographis     inusta    var. macularis(Leight.)  A.L.       Sm.     1861").should == "Phaeographis inusta macularis"
  end
  
#  "subsect."/"subtrib."/"subgen."/"morph."/"trib."/
it "should parse name with morph." do
  val = "Callideriphus flavicollis morph. reductus Fuchs 1961"
  parse(val).should_not be_nil
  (val).should == "Callideriphus flavicollis morph. reductus Fuchs 1961"
  canonical(val).should == "Callideriphus flavicollis reductus"
  #details(val).should == {}
end

  
  it "should parse name with forma/fo./form./f." do
    parse("Caulerpa cupressoides forma nuda").should_not be_nil
    value("Caulerpa cupressoides forma nuda").should == "Caulerpa cupressoides f. nuda"
    canonical("Caulerpa cupressoides forma nuda").should == "Caulerpa cupressoides nuda"
    details("Caulerpa cupressoides forma nuda").should == {:genus=>"Caulerpa", :species=>"cupressoides", :subspecies=>[{:rank=>"f.", :value=>"nuda"}]}
    parse("Chlorocyperus glaber form. fasciculariforme (Lojac.) Soó").should_not be_nil
    value("Chlorocyperus glaber form. fasciculariforme (Lojac.) Soó").should == "Chlorocyperus glaber f. fasciculariforme (Lojac.) Soó"
    canonical("Chlorocyperus glaber form. fasciculariforme (Lojac.) Soó").should == "Chlorocyperus glaber fasciculariforme"
    details("Chlorocyperus glaber form. fasciculariforme (Lojac.) Soó").should == {:genus=>"Chlorocyperus", :species=>"glaber", :subspecies=>[{:rank=>"f.", :value=>"fasciculariforme"}], :orig_authors=>{:names=>["Lojac."]}, :authors=>{:names=>["Soó"]}}
    parse("Bambusa nana Roxb. fo. alphonse-karri (Mitford ex Satow) Makino ex Shiros.").should_not be_nil
    value("Bambusa nana Roxb. fo. alphonse-karri (Mitford ex Satow) Makino ex Shiros.").should == "Bambusa nana Roxb. f. alphonse-karri (Mitford ex Satow) Makino ex Shiros."
    canonical("Bambusa nana Roxb. fo. alphonse-karri (Mitford ex Satow) Makino ex Shiros.").should == "Bambusa nana alphonse-karri"
    details("Bambusa nana Roxb. fo. alphonse-karri (Mitford ex Satow) Makino ex Shiros.").should == {:genus=>"Bambusa", :species=>"nana", :subspecies=>[{:rank=>"f.", :value=>"alphonse-karri"}], :species_authors=>{:authors=>{:names=>["Roxb."]}}, :subspecies_authors=>{:original_revised_name_authors=>{:revised_authors=>{:names=>["Mitford"]}, :authors=>{:names=>["Satow"]}}, :revised_name_authors=>{:revised_authors=>{:names=>["Makino"]}, :authors=>{:names=>["Shiros."]}}}}
    parse("Sphaerotheca fuliginea f. dahliae Movss. 1967").should_not be_nil
    value("   Sphaerotheca    fuliginea     f.    dahliae    Movss.   1967    ").should == "Sphaerotheca fuliginea f. dahliae Movss. 1967"
    canonical("Sphaerotheca fuliginea f. dahliae Movss. 1967").should == "Sphaerotheca fuliginea dahliae"
    details("Sphaerotheca fuliginea f. dahliae Movss. 1967").should ==  {:subspecies=>[{:rank=>"f.", :value=>"dahliae"}], :authors=>{:year=>"1967", :names=>["Movss."]}, :species=>"fuliginea", :genus=>"Sphaerotheca"} 
  end
  
  it "should parse name with several subspecies names NOT BOTANICAL CODE BUT NOT INFREQUENT" do
    parse("Hydnellum scrobiculatum var. zonatum f. parvum (Banker) D. Hall & D.E. Stuntz 1972").should_not be_nil
    value("Hydnellum scrobiculatum var. zonatum f. parvum (Banker) D. Hall & D.E. Stuntz 1972").should == "Hydnellum scrobiculatum var. zonatum f. parvum (Banker) D. Hall et D.E. Stuntz 1972"
    details("Hydnellum scrobiculatum var. zonatum f. parvum (Banker) D. Hall & D.E. Stuntz 1972").should == {:orig_authors=>{:names=>["Banker"]}, :subspecies=>[{:rank=>"var.", :value=>"zonatum"}, {:rank=>"f.", :value=>"parvum"}], :species=>"scrobiculatum", :authors=>{:year=>"1972", :names=>["D. Hall", "D.E. Stuntz"]}, :genus=>"Hydnellum", :is_valid=>false}  
  end
  
  it "should parse status BOTANICAL RARE" do
    #it is always latin abbrev often 2 words
    parse("Arthopyrenia hyalospora (Nyl.) R.C. Harris comb. nov.").should_not be_nil
    value("Arthopyrenia hyalospora (Nyl.) R.C. Harris comb. nov.").should == "Arthopyrenia hyalospora (Nyl.) R.C. Harris comb. nov."
    canonical("Arthopyrenia hyalospora (Nyl.) R.C. Harris comb. nov.").should == "Arthopyrenia hyalospora"
    details("Arthopyrenia hyalospora (Nyl.) R.C. Harris comb. nov.").should ==  {:status=>"comb. nov.", :orig_authors=>{:names=>["Nyl."]}, :species=>"hyalospora", :authors=>{:names=>["R.C. Harris"]}, :genus=>"Arthopyrenia"}
  end
  
  it "should parse name without a year but with authors" do 
    parse("Arthopyrenia hyalospora (Nyl.) R.C. Harris").should_not be_nil
    value("Arthopyrenia hyalospora(Nyl.)R.C.     Harris").should == "Arthopyrenia hyalospora (Nyl.) R.C. Harris"
    canonical("Arthopyrenia hyalospora (Nyl.) R.C. Harris").should == "Arthopyrenia hyalospora"
  end
  
  it "should parse revised (ex) names" do
    #invalidly published
    parse("Arthopyrenia hyalospora (Nyl. ex Banker) R.C. Harris").should_not be_nil
    value("Arthopyrenia hyalospora (Nyl. ex Banker) R.C. Harris").should == "Arthopyrenia hyalospora (Nyl. ex Banker) R.C. Harris"
    canonical("Arthopyrenia hyalospora (Nyl. ex Banker) R.C. Harris").should == "Arthopyrenia hyalospora"
    details("Arthopyrenia hyalospora (Nyl. ex Banker) R.C. Harris").should == {:species=>"hyalospora", :authors=>{:names=>["R.C. Harris"]}, :genus=>"Arthopyrenia", :original_revised_name_authors=>{:authors=>{:names=>["Banker"]}, :revised_authors=>{:names=>["Nyl."]}}}    
    parse("Arthopyrenia hyalospora Nyl. ex Banker").should_not be_nil
    
    parse("Glomopsis lonicerae Peck ex C.J. Gould 1945").should_not be_nil
    details("Glomopsis lonicerae Peck ex C.J. Gould 1945").should == {:revised_name_authors=>{:authors=>{:year=>"1945", :names=>["C.J. Gould"]}, :revised_authors=>{:names=>["Peck"]}}, :species=>"lonicerae", :genus=>"Glomopsis"}
  
    parse("Acanthobasidium delicatum (Wakef.) Oberw. ex Jülich 1979").should_not be_nil
    parse("Mycosphaerella eryngii (Fr. ex Duby) Johanson ex Oudem. 1897").should_not be_nil
    details("Mycosphaerella eryngii (Fr. ex Duby) Johanson ex Oudem. 1897").should == {:original_revised_name_authors=>{:authors=>{:names=>["Duby"]}, :revised_authors=>{:names=>["Fr."]}}, :species=>"eryngii", :genus=>"Mycosphaerella", :revised_name_authors=>{:authors=>{:year=>"1897", :names=>["Oudem."]}, :revised_authors=>{:names=>["Johanson"]}}}
    #invalid but happens
    parse("Mycosphaerella eryngii (Fr. Duby) ex Oudem. 1897").should_not be_nil
    parse("Mycosphaerella eryngii (Fr.ex Duby) ex Oudem. 1897").should_not be_nil
    parse("Salmonella werahensis (Castellani) Hauduroy and Ehringer in Hauduroy 1937").should_not be_nil
  end
  
  it "should parse multiplication sign" do
    parse("Arthopyrenia x hyalospora (Nyl.) R.C. Harris").should_not be_nil
    details("Arthopyrenia x hyalospora (Nyl. ex Banker) R.C. Harris").should == {:original_revised_name_authors=>{:authors=>{:names=>["Banker"]}, :revised_authors=>{:names=>["Nyl."]}}, :species=>"hyalospora", :authors=>{:names=>["R.C. Harris"]}, :genus=>"Arthopyrenia", :cross=>"inside"}
    parse("Arthopyrenia X hyalospora(Nyl. ex Banker) R.C. Harris").should_not be_nil
    parse("x Arthopyrenia hyalospora (Nyl. ex Banker) R.C. Harris").should_not be_nil
    details("x Arthopyrenia hyalospora (Nyl. ex Banker) R.C. Harris").should == {:original_revised_name_authors=>{:authors=>{:names=>["Banker"]}, :revised_authors=>{:names=>["Nyl."]}}, :species=>"hyalospora", :authors=>{:names=>["R.C. Harris"]}, :genus=>"Arthopyrenia", :cross=>"before"}
    parse("X Arthopyrenia (Nyl. ex Banker) R.C. Harris").should_not be_nil
    details("X Arthopyrenia (Nyl. ex Banker) R.C. Harris").should == {:uninomial=>"Arthopyrenia", :original_revised_name_authors=>{:authors=>{:names=>["Banker"]}, :revised_authors=>{:names=>["Nyl."]}}, :authors=>{:names=>["R.C. Harris"]}, :cross=>"before"}
    #ascii for multiplication
    parse("Melampsora × columbiana G. Newc. 2000").should_not be_nil
  end
  
  it "should parse hybrid combination" do
    parse("Arthopyrenia hyalospora X Hydnellum scrobiculatum").should_not be_nil
    value("Arthopyrenia hyalospora X Hydnellum scrobiculatum").should == "Arthopyrenia hyalospora \303\227 Hydnellum scrobiculatum"
    canonical("Arthopyrenia hyalospora X Hydnellum scrobiculatum").should == "Arthopyrenia hyalospora \303\227 Hydnellum scrobiculatum"
    details("Arthopyrenia hyalospora x Hydnellum scrobiculatum").should == {:hybrid=>{:scientific_name1=>{:species=>"hyalospora", :genus=>"Arthopyrenia"}, :scientific_name2=>{:species=>"scrobiculatum", :genus=>"Hydnellum"}}}
    
    parse("Arthopyrenia hyalospora (Banker) D. Hall x Hydnellum scrobiculatum D.E. Stuntz").should_not be_nil
    value("Arthopyrenia hyalospora (Banker) D. Hall X Hydnellum scrobiculatum D.E. Stuntz").should == "Arthopyrenia hyalospora (Banker) D. Hall \303\227 Hydnellum scrobiculatum D.E. Stuntz"
    canonical("Arthopyrenia hyalospora (Banker) D. Hall X Hydnellum scrobiculatum D.E. Stuntz").should == "Arthopyrenia hyalospora \303\227 Hydnellum scrobiculatum"
    
    parse("Arthopyrenia hyalospora x").should_not be_nil
    value("Arthopyrenia hyalospora X").should == "Arthopyrenia hyalospora \303\227 ?"  
    canonical("Arthopyrenia hyalospora x").should == "Arthopyrenia hyalospora"
    details("Arthopyrenia hyalospora x").should == {:hybrid=>{:scientific_name1=>{:species=>"hyalospora", :genus=>"Arthopyrenia"}, :scientific_name2=>"?"}}  
    parse("Arthopyrenia hyalospora × ?").should_not be_nil
    details("Arthopyrenia hyalospora × ?").should == {:hybrid=>{:scientific_name1=>{:species=>"hyalospora", :genus=>"Arthopyrenia"}, :scientific_name2=>"?"}}
  end

  

  it "should parse name with subspecies without rank NOT BOTANICAL" do
    name = "Hydnellum scrobiculatum zonatum (Banker) D. Hall & D.E. Stuntz 1972"
    parse(name).should_not be_nil
    value(name).should == "Hydnellum scrobiculatum zonatum (Banker) D. Hall et D.E. Stuntz 1972"
    canonical(name).should == "Hydnellum scrobiculatum zonatum"
    details(name).should == {:orig_authors=>{:names=>["Banker"]}, :subspecies=>{:rank=>"n/a", :value=>"zonatum"}, :species=>"scrobiculatum", :authors=>{:year=>"1972", :names=>["D. Hall", "D.E. Stuntz"]}, :genus=>"Hydnellum"}
    sp = "Begonia pingbienensis angustior"
    parse(sp).should_not be_nil
    details(sp).should == {:genus=>"Begonia", :species=>"pingbienensis", :subspecies=>{:rank=>"n/a", :value=>"angustior"}}
  end
  
  it "should not parse utf-8 chars in name part" do
    parse("Érematosphaeria phaespora").should be_nil
    parse("Trematosphaeria phaeáapora").should be_nil
  end
  
  it "should parse some invalid names" do
    parse("Acarospora cratericola 1929").should_not be_nil
    parse("Agaricus acris var. (b.)").should_not be_nil  
    value("Agaricus acris var. (b.)").should == "Agaricus acris var. (b.)"  
    parse("Agaricus acris var. (b.)").should_not be_nil 
    value("Agaricus acris var. (b.&c.)").should == "Agaricus acris var. (b.c.)"  
    details("Agaricus acris var. (b.&c.)").should == {:editorial_markup=>"(b.c.)", :subspecies=>[{:rank=>"var.", :value=>nil}], :species=>"acris", :genus=>"Agaricus", :is_valid=>false}

  end

  # Moraea spathulata ( (L. f.) ) Klatt
  # Eichornia crassipes ( (Martius) ) Solms-Laub.
  # Vitex agnus-castus fo. alba ( (West.) ) Rehder
  # Pelargonium cucullatum ( (L.) ) L'Her.
  # Meiostemon humbertii ( (H. Perrier) ) Exell & Stace
  # it 'should parse double parenthesis' do
  #   val = "Eichornia crassipes ( (Martius) Solms-Laub."
  #   parse(val).should_not be_nil
  #   value(val).should == "Eichornia crassipes (Martius) Solms-Laub."
  # end

  
end
