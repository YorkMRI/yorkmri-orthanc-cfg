function Initialize()
  print('initialize')
end

function makeValidLabel(input)
  local invalidCharacters = "[^%w_-]"
  return input:gsub(invalidCharacters, "-")
end

function OnStableStudy(studyId, tags, metadata)
  --PrintRecursive(tags)
  local studyInstUid = tags["StudyInstanceUID"] 
  local referringPhysicianName = tags["ReferringPhysicianName"]
  print('OnStableStudy: StableAge elapsed, processing study ' .. studyInstUid .. ' with ReferringPhysician ' .. referringPhysicianName)
  RestApiPut("/studies/" .. studyId .. "/labels/refdoc-" .. makeValidLabel(referringPhysicianName), '')
end

function Finalize()
  print('finalize')
end
