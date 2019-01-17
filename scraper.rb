#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MemberList < Scraped::JSON
  field :members do
    json[:@graph].select { |m| m[:@type] == 'Person' }.map { |m| fragment(m => Member).to_h }
  end
end

class Member < Scraped::JSON
  field :id do
    json[:@id]
  end

  field :name do
    json[:"http://example.com/F31CBD81AD8343898B49DC65743F0BDF"]
  end

  # sometimes this has more than one entry. The current one *seems* to
  # be the last, but we might need to look them up for start dates
  field :party do
    [json[:partyMemberHasPartyMembership]].flatten.map { |m| m.dig(:partyMembershipHasParty, :@id) }.last
  end

  field :constituency do
    json.dig(:memberHasParliamentaryIncumbency, :seatIncumbencyHasHouseSeat, :houseSeatHasConstituencyGroup, :@id)
  end

  field :constituency_name do
    json.dig(:memberHasParliamentaryIncumbency, :seatIncumbencyHasHouseSeat, :houseSeatHasConstituencyGroup, :constituencyGroupName)
  end
end

url = 'https://api.parliament.uk/query/house_current_members.json?house_id=1AFu55Hs'
Scraped::Scraper.new(url => MemberList).store(:members)
