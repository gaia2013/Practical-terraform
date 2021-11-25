resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform"  # 全世界で一意にしなければならない

  versioning {	# versioningの設定を有効にすると、オブジェクトを変更・削除しても、以前のバージョンを復元できる
    enabled = true
  }

  server_side_encryption_configuration { 
    rule {
      apply_server_side_encryption_by_default {
	sse_algorithm = "AES256"
      }
    }
  }
}

# 特に理由がなければ、すべての設定を有効にする。
resource "aws_s3_bucket_public_access_block" "private" {
  bucket	    = aws_s3_bucket.private.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# 外部公開するpublic_bucket
resource "aws_s3_bucket" "public" {
  bucket  = "public-pragmatic-terraform"
  acl	  = "public-read"		  

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

# list6.4 ログバケットの定義
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

# バケットポリシーの定義 ALBようなAWSサービスから、S3へ書き込みを行う場合に必要。
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]
    principals {
      type	  = "AWS"
      identifiers = ["582318560864"]
    }
  }
}

# S3バケットの削除
# resource "aws_s3_bucket" "force_destroy" {
#   bucket	= "force-destroy-pragmatic-terraform"
#   force_destroy = true
# }

