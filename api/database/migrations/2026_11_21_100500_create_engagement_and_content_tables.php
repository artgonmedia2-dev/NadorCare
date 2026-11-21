<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('intervention_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignUlid('author_id')->constrained('users')->restrictOnDelete();
            $table->foreignUlid('professional_id')->constrained()->restrictOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->boolean('is_published')->default(true);
            $table->foreignUlid('moderated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampsTz();
        });

        Schema::create('complaints', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUlid('user_id')->constrained()->restrictOnDelete();
            $table->string('type', 30);
            $table->text('description'); // chiffré
            $table->string('status', 20)->default('open')->index();
            $table->foreignUlid('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->text('resolution')->nullable();
            $table->timestampsTz();
        });

        Schema::create('conversations', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->string('status', 20)->default('open')->index();
            $table->foreignUlid('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('last_message_at')->nullable();
            $table->timestampsTz();
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('sender_id')->constrained('users')->restrictOnDelete();
            $table->text('body')->nullable(); // chiffré
            $table->foreignUlid('file_id')->nullable()->constrained()->nullOnDelete();
            $table->timestampTz('read_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();
            $table->index(['conversation_id', 'created_at']);
        });

        Schema::create('notification_templates', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('key');
            $table->string('channel', 20); // push | sms | whatsapp
            $table->jsonb('body');
            $table->boolean('is_active')->default(true);
            $table->timestampsTz();
            $table->unique(['key', 'channel']);
        });

        Schema::create('notification_logs', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUlid('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->string('channel', 20);
            $table->string('template_key')->nullable();
            $table->string('recipient');
            $table->string('status', 20)->default('queued')->index();
            $table->string('provider_message_id')->nullable();
            $table->text('error')->nullable();
            $table->timestampTz('sent_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });

        Schema::create('pages', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('slug')->unique();
            $table->jsonb('title');
            $table->jsonb('body')->nullable();
            $table->jsonb('seo')->nullable();
            $table->boolean('is_published')->default(false);
            $table->timestampsTz();
        });

        Schema::create('faqs', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->jsonb('question');
            $table->jsonb('answer');
            $table->string('category')->nullable();
            $table->unsignedSmallInteger('sort')->default(0);
            $table->boolean('is_published')->default(true);
            $table->timestampsTz();
        });

        Schema::create('banners', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('app', 10)->default('patient');
            $table->jsonb('title');
            $table->foreignUlid('image_file_id')->nullable()->constrained('files')->nullOnDelete();
            $table->string('link')->nullable();
            $table->timestampTz('starts_at')->nullable();
            $table->timestampTz('ends_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort')->default(0);
            $table->timestampsTz();
        });

        Schema::create('posts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('slug')->unique();
            $table->jsonb('title');
            $table->jsonb('excerpt')->nullable();
            $table->jsonb('body')->nullable();
            $table->jsonb('seo')->nullable();
            $table->foreignUlid('cover_file_id')->nullable()->constrained('files')->nullOnDelete();
            $table->foreignUlid('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('published_at')->nullable()->index();
            $table->timestampsTz();
        });

        Schema::create('professional_applications', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('name');
            $table->string('phone', 20);
            $table->foreignUlid('professional_category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('city')->nullable();
            $table->text('message')->nullable();
            $table->foreignUlid('file_id')->nullable()->constrained()->nullOnDelete();
            $table->string('status', 20)->default('new')->index();
            $table->timestampsTz();
        });

        Schema::create('contact_messages', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('name');
            $table->string('phone', 20)->nullable();
            $table->string('email')->nullable();
            $table->text('message');
            $table->timestampTz('handled_at')->nullable();
            $table->timestampTz('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        foreach (['contact_messages', 'professional_applications', 'posts', 'banners', 'faqs', 'pages',
            'notification_logs', 'notification_templates', 'messages', 'conversations', 'complaints', 'reviews'] as $table) {
            Schema::dropIfExists($table);
        }
    }
};
