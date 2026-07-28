Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SetOutputToWaveFile("d:\capstone\Vocaboo\backend\pencil.wav")
$synth.Speak("pencil")
$synth.Dispose()
Write-Host "Generated pencil.wav successfully"
