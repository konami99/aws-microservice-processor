import { Context, Handler } from "aws-lambda"

const handler: Handler = async (event: any, context: Context) =>{
  console.log(event)
  console.log(context)

  return {
    statusCode: 200,
  }
}

export { handler }