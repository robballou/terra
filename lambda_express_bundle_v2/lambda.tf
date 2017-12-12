resource "aws_lambda_function" "current" {
  filename         = "${var.lambda_path}/lambda.zip"
  function_name    = "${var.config["prefix"]}-${var.subdomain}"
  role             = "${var.lambda_role_arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "${var.lambda_runtime}"
  memory_size      = "${var.lambda_memory_size}"
  timeout          = "${var.lambda_timeout}"
  environment {
    variables = "${var.lambda_environment_variables}"
  }
}

resource "null_resource" "npm" {
  triggers {
    package = "${uuid()}"
  }

  provisioner "local-exec" {
    command = "cd ${var.lambda_path} && npm install && zip -r lambda.zip ."
  }
}

resource "aws_lambda_permission" "current" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.current.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.current.id}/*/*"
}
