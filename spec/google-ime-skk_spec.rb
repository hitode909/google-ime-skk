# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'kconv'

describe "GoogleImeSkk" do
  it "can search" do
    ime = GoogleImeSkk.new("localhost", 12343, nil, 3600)
    Kconv.toutf8(ime.social_ime_search(Kconv.toeuc("ねこ"))).should match "猫"
  end
end
