-- Function to check if table empty see https://stackoverflow.com/a/10114940
function table.empty(self)
  for _,_ in pairs(self) do
    return false
  end
  return true
end
