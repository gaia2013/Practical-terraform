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
