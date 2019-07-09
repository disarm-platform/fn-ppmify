function(params) {
  # run function and catch result

  result = params[['number']] + 1

  if (result == 1) stop('FAKE ERROR: Do not give me zero')
  
  # wrap up result to match output structure from docs
  response = list(unbox(result))

  return(response)
}
