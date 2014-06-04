# encoding: utf-8

Mutant::Meta::Example.add do
  source 'a ||= 1'

  mutation 'a__mutant__ ||= 1'
  mutation 'a ||= nil'
  mutation 'a ||= 0'
  mutation 'a ||= -1'
  mutation 'a ||= 2'
  mutation 'nil'
end

Mutant::Meta::Example.add do
  source '@a ||= 1'

  mutation '@a ||= nil'
  mutation '@a ||= 0'
  mutation '@a ||= -1'
  mutation '@a ||= 2'
  mutation 'nil'
end
