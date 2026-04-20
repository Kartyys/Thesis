import json
import subprocess
import os

def lambda_handler(event, context):
    """
    En avsiktligt sårbar Lambda funktion som tillåter OS Command Injection.
    I ett verkligt scenario kanske denna tar emot en bild för konvertering,
    men här tar vi emot ett filnamn eller parameter direkt från användaren.
    """
    try:
        # Hämtar parametern 'command' direkt från eventet 
        user_input = event.get('command', 'whoami')

        # DÅLIG PRAXIS: Kör indatan direkt som ett systemkommando
        print(f"Executing command: {user_input}")
        result = subprocess.run(user_input, shell=True, capture_output=True, text=True)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'stdout': result.stdout,
                'stderr': result.stderr
            })
        }
    except Exception as e:
         return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }